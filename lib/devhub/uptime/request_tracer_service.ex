defmodule Devhub.Uptime.RequestTracerService do
  @moduledoc false
  use GenServer

  alias DevhubProtos.RequestTracer.V1
  alias DevhubProtos.RequestTracer.V1.RequestTracerService.Stub

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_opts) do
    {:ok, channel} = GRPC.Stub.connect("localhost:50052")
    {:ok, %{channel: channel}}
  end

  @impl true
  def handle_call({:trace_request, service}, _from, %{channel: channel} = state) do
    request = %V1.TraceRequest{
      url: service.url,
      method: service.method,
      request_body: service.request_body,
      request_headers:
        Enum.map(service.request_headers, fn %{key: key, value: value} ->
          %V1.Header{key: key, value: value}
        end)
    }

    case Stub.trace(channel, request) do
      {:ok, result} -> {:reply, {:ok, result}, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_info({:gun_down, _pid, :http2, :closed, []}, state) do
    {:noreply, state}
  end

  def handle_info({:gun_up, _pid, :http2}, state) do
    {:noreply, state}
  end
end
