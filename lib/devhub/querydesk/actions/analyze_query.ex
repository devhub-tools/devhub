defmodule Devhub.QueryDesk.Actions.AnalyzeQuery do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.QueryDesk.Utils.GetConnectionPid

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query
  alias Ecto.Adapters.SQL
  alias Ecto.Repo.Transaction

  @callback analyze_query(Query.t()) :: {:ok, Query.t()} | {:error, String.t()}
  def analyze_query(query) do
    {:ok, query} =
      QueryDesk.update_query(query, %{
        query: "EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) " <> query.query,
        executed_at: DateTime.utc_now()
      })

    case do_analyze_query(query, []) do
      {:ok, plan} -> QueryDesk.update_query(query, %{plan: plan})
      error -> error
    end
  end

  def do_analyze_query(query, opts) do
    if is_nil(query.credential.database.agent_id) or Application.get_env(:devhub, :agent) do
      {:ok, pid} = get_connection_pid(query.credential, temporary: true, timeout: query.timeout * 1000)

      # because we rolled back it will always return an error
      # we do this so that the queries don't actually execute
      {:error, result} =
        Transaction.transact(
          __MODULE__,
          pid,
          fn ->
            result =
              pid
              |> SQL.query(query.query)
              |> case do
                {:ok, %Postgrex.Result{rows: [[[plan]]]}} -> {:ok, plan}
                _error -> {:error, "Failed to analyze query"}
              end

            Transaction.rollback(pid, result)
          end,
          Ecto.Repo.Supervisor.tuplet(pid, [])
        )

      result
    else
      DevhubWeb.AgentConnection.send_command(
        query.credential.database.agent_id,
        {__MODULE__, :do_analyze_query, [query, opts]}
      )
    end
  end
end
