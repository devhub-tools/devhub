defmodule DevhubWeb.AgentConnection do
  @moduledoc "The server side of an agent connection"

  def send_command(agent_id, fun, opts \\ []) do
    ref = opts[:ref] || Ecto.UUID.generate()

    encoded_fun =
      {ref, fun}
      |> :erlang.term_to_binary()
      |> :zlib.gzip()

    case :ets.lookup(DevhubWeb.AgentConnection, agent_id) do
      [{^agent_id, pid}] ->
        pid
        |> send({:send, opts[:forward_to] || self(), ref, encoded_fun})
        |> case do
          {:send, _self, _ref, _fun} ->
            receive do
              {:command_finished, result} -> result
              {:error, error} -> {:error, error}
            end

          {:error, error} ->
            {:error, error}
        end

      [] ->
        {:error, :agent_not_online}
    end
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_in({message, [opcode: :binary]}, state) do
    case :erlang.binary_to_term(message) do
      {:pubsub, topic_id, message} ->
        Phoenix.PubSub.broadcast(Devhub.PubSub, topic_id, message)

      {_task_ref, {ref, message}} when is_binary(ref) ->
        send(state[ref], message)

      {ref, {:message_from_database, data}} ->
        Phoenix.PubSub.broadcast(Devhub.PubSub, ref, {:message_from_database, data})

      _message ->
        :ok
    end

    {:ok, state}
  end

  def handle_control(_frame, state) do
    Phoenix.PubSub.broadcast(Devhub.PubSub, state.agent_id, :connected)
    :ets.insert(__MODULE__, {state.agent_id, self()})
    {:ok, state}
  end

  def terminate(_reason, state) do
    # Only delete the entry if this process is the current one for this agent_id
    with [{_agent_id, pid}] <- :ets.lookup(__MODULE__, state.agent_id),
         true <- pid == self() do
      :ets.delete(__MODULE__, state.agent_id)
    end

    :ok
  end

  def handle_info({:send, from, ref, message}, state) do
    {:push, {:binary, message}, Map.put(state, ref, from)}
  end
end
