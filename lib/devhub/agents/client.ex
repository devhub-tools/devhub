defmodule Devhub.Agents.Client do
  @moduledoc false
  use WebSockex

  alias Phoenix.PubSub

  require Logger

  def start_link(opts) do
    %{"token" => token} = config = Application.get_env(:devhub, :agent_config)

    host = config["endpoint"] || DevhubWeb.Endpoint.url()

    WebSockex.start_link("#{host}/agents/socket?token=#{token}", __MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def handle_connect(_conn, state) do
    PubSub.subscribe(Devhub.PubSub, "agent")

    send(self(), :ping)
    :timer.send_interval(to_timeout(second: 45), :ping)

    {:ok, state}
  end

  def handle_info(:ping, state) do
    {:reply, :ping, state}
  end

  def handle_info(message, state) do
    encoded = :erlang.term_to_binary(message)
    {:reply, {:binary, encoded}, state}
  end

  def handle_frame({:binary, encoded_fun}, state) do
    {ref, {module, function, args}} =
      encoded_fun
      |> :zlib.gunzip()
      |> :erlang.binary_to_term()

    Task.Supervisor.async_nolink(Devhub.TaskSupervisor, fn ->
      try do
        {ref, {:command_finished, apply(module, function, args)}}
      rescue
        error ->
          Logger.error("Failed to run command: " <> Exception.format(:error, error, __STACKTRACE__))
          {ref, {:error, error}}
      end
    end)

    {:ok, state}
  end

  # coveralls-ignore-next-line
  def handle_disconnect(_status, state) do
    PubSub.unsubscribe(Devhub.PubSub, "agent")

    {:reconnect, state}
  end
end
