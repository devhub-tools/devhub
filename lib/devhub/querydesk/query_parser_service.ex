defmodule Devhub.QueryDesk.QueryParserService do
  @moduledoc false
  use GenServer

  alias DevhubProtos.QueryParser.V1.ParseQueryRequest
  alias DevhubProtos.QueryParser.V1.QueryParserService.Stub

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def parse_query(query) do
    case GenServer.call(__MODULE__, {:parse_query, query}) do
      {:error, %GRPC.RPCError{message: message}} ->
        {:error, message}

      json ->
        Jason.decode!(json)
    end
  end

  @impl true
  def init(_opts) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")
    {:ok, %{channel: channel}}
  end

  @impl true
  def handle_call({:parse_query, query}, _from, %{channel: channel} = state) do
    request = %ParseQueryRequest{query: query}

    case Stub.parse_query(channel, request) do
      {:ok, %{json_result: json}} -> {:reply, json, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_info({:gun_down, _pid, :http2, _reason, []}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_up, _pid, :http2}, state) do
    {:noreply, state}
  end
end
