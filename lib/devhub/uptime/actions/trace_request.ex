defmodule Devhub.Uptime.Actions.TraceRequest do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Uptime.Schemas.Service
  alias DevhubProtos.RequestTracer.V1

  require Logger

  @callback trace_request(Service.t()) :: {:ok, V1.TraceResponse.t()} | {:error, any()}
  def trace_request(service) do
    :poolboy.transaction(
      :request_tracer_service_worker,
      fn pid ->
        try do
          GenServer.call(pid, {:trace_request, service}, service.timeout_ms)
        catch
          :exit, {:timeout, _genserver_call} ->
            {:error, :timeout}

          # coveralls-ignore-start
          :exit, error ->
            Logger.error("Failed to trace request: " <> inspect(error))
            {:error, :request_trace_failed}

          error ->
            Logger.error("Failed to trace request: " <> inspect(error))
            {:error, :request_trace_failed}
            # coveralls-ignore-stop
        end
      end,
      # adding a bit more time to allow wrapping up nicely
      service.timeout_ms + 100
    )
  end
end
