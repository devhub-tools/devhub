defmodule Devhub.QueryDesk.Actions.RunQuery do
  @moduledoc false
  @behaviour __MODULE__

  use Devhub.Utils.WithSpan

  import Devhub.QueryDesk.Utils.GetConnectionPid

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query
  alias Ecto.Adapters.SQL
  alias Ecto.Repo.Transaction

  require Logger

  @decorate_all with_span()

  @callback run_query(Query.t(), Keyword.t()) ::
              {:ok, Postgrex.Result.t() | MyXQL.Result.t() | Ch.Result.t() | :stream, Query.t()}
              | {:error, any(), Query.t()}
  def run_query(query, opts) do
    query = QueryDesk.preload_query_for_run(query)

    cond do
      QueryDesk.can_run_query?(query) ->
        with {:ok, query_string} <- protect_query(query),
             {:ok, query} <-
               QueryDesk.update_query(query, %{
                 query: query_string,
                 executed_at: DateTime.utc_now()
               }) do
          query
          |> do_run_query(opts)
          |> handle_query_result(query)
        else
          error ->
            QueryDesk.update_query(query, %{
              failed: true,
              error: "Failed to parse query",
              executed_at: DateTime.utc_now()
            })

            error
        end

      is_nil(query.executed_at) ->
        {:error, :pending_approval, query}

      true ->
        {:error, "Query was already executed."}
    end
  end

  def do_run_query(query, opts) do
    if is_nil(query.credential.database.agent_id) or Application.get_env(:devhub, :agent) do
      {:ok, pid} =
        get_connection_pid(query.credential,
          temporary: opts[:stream?] == true or query.timeout > 10,
          timeout: query.timeout * 1000
        )

      result =
        if opts[:stream?] do
          stream_query(pid, query)
        else
          queries =
            if opts[:single?] do
              [query.query]
            else
              query.query |> String.trim() |> String.split(";", trim: true)
            end

          Enum.map(queries, fn query -> SQL.query(pid, query) end)
        end

      maybe_terminate_connection(result, pid)
    else
      DevhubWeb.AgentConnection.send_command(
        query.credential.database.agent_id,
        {__MODULE__, :do_run_query, [query, opts]}
      )
    end
  end

  if Code.ensure_loaded?(Devhub.DataProtection) do
    defdelegate protect_query(query), to: Devhub.DataProtection
  else
    defp protect_query(query), do: {:ok, query.query}
  end

  defp maybe_terminate_connection({:error, %DBConnection.ConnectionError{}} = error, pid) do
    DynamicSupervisor.terminate_child(Devhub.QueryDesk.RepoSupervisor, pid)
    error
  end

  defp maybe_terminate_connection(result, _pid) do
    result
  end

  defp handle_query_result({:stream, task}, query) do
    {:ok, {:stream, task}, query}
  end

  defp handle_query_result([{:ok, result}], query) do
    {:ok, result, query}
  end

  defp handle_query_result([error], query) do
    message = parse_query_error(error)
    {:ok, query} = QueryDesk.update_query(query, %{failed: true, error: message})
    {:error, message, query}
  end

  defp handle_query_result(result, query) when is_list(result) do
    results =
      Enum.map(result, fn
        {:error, error} ->
          error = parse_query_error({:error, error})
          "ERROR: #{error}"

        {:ok, %{command: command, num_rows: num_rows}} ->
          "#{command} #{num_rows}"
      end)

    if Enum.all?(result, &match?({:ok, _result}, &1)) do
      {:ok, results, query}
    else
      message = Enum.join(results, "\n")
      {:ok, query} = QueryDesk.update_query(query, %{failed: true, error: message})
      {:error, results, query}
    end
  end

  defp parse_query_error({:error, %Postgrex.Error{postgres: %{message: message}}}) do
    message
  end

  defp parse_query_error({:error, %Ch.Error{message: message}}) do
    message
  end

  defp parse_query_error({:error, %DBConnection.ConnectionError{}}) do
    "Database connection error"
  end

  defp parse_query_error({:error, error}) when is_binary(error) do
    error
  end

  defp parse_query_error(error) do
    Logger.error("unhandled query error: #{inspect(error)}")
    "Something went wrong, please try again."
  end

  defp stream_query(pid, query) do
    # we don't want this process finishing to kill the connection as the query is run in the task
    Process.unlink(pid)

    task =
      Task.Supervisor.async_nolink(Devhub.TaskSupervisor, fn ->
        # we want the task linked to the connection pid so that if either is terminated, the other is notified
        Process.link(pid)

        try do
          do_stream_query(pid, query)
        rescue
          error ->
            error_msg = parse_query_error({:error, error})
            msg = %{error: error_msg} |> Jason.encode!() |> :brotli.encode(%{quality: 5})
            broadcast(query.id, {:query_stream, {:chunk, msg, {:error, error_msg}}})
        after
          broadcast(query.id, {:query_stream, :done})

          # need to make sure the connection is killed after the task is done
          Process.exit(pid, :kill)
        end
      end)

    {:stream, task}
  end

  defp do_stream_query(pid, %{credential: %{database: %{adapter: :clickhouse}}} = query) do
    %{command: command, columns: columns, rows: rows} =
      SQL.query!(pid, query.query, [], settings: [max_execution_time: query.timeout * 1000, limit: query.limit])

    rows
    |> Enum.chunk_every(10)
    |> Enum.map(fn chunk ->
      %Ch.Result{
        command: command,
        columns: columns,
        rows: chunk,
        num_rows: length(chunk)
      }
    end)
    |> handle_stream(query)
  end

  defp do_stream_query(pid, query) do
    Transaction.transact(
      __MODULE__,
      pid,
      fn ->
        pid
        |> SQL.stream(query.query, [], max_rows: 10)
        |> handle_stream(query)
      end,
      Ecto.Repo.Supervisor.tuplet(pid, [])
    )
  end

  defp handle_stream(stream, query) do
    # credo complains about not using the result of reduce but we need it for the count
    # credo:disable-for-next-line
    Enum.reduce_while(stream, 0, fn chunk, acc ->
      msg =
        chunk
        |> Map.from_struct()
        |> Map.update(:rows, [], fn rows ->
          Enum.map(rows || [], fn row ->
            Enum.map(row, &QueryDesk.format_field/1)
          end)
        end)
        |> Map.take([:command, :columns, :rows, :num_rows])
        |> Jason.encode!()
        |> :brotli.encode(%{quality: 5})

      broadcast(query.id, {:query_stream, {:chunk, msg}})

      count = acc + length(chunk.rows || [])

      if count >= query.limit do
        {:halt, count}
      else
        {:cont, count}
      end
    end)

    {:ok, :done}
  end

  defp broadcast(query_id, msg) do
    Phoenix.PubSub.broadcast(Devhub.PubSub, query_id, msg)
    Phoenix.PubSub.broadcast(Devhub.PubSub, "agent", {:pubsub, query_id, msg})
  end
end
