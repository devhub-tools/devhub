defmodule Devhub.Uptime.Actions.CheckService do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Service
  alias DevhubProtos.RequestTracer.V1

  @callback check_service(Service.t()) :: {:ok, V1.TraceResponse.t()} | {:error, any()}
  def check_service(service) do
    case Uptime.trace_request(service) do
      {:ok, result} -> check_status(service, result)
      {:error, error} -> {:error, error}
    end
  end

  defp check_status(service, result) do
    case Service.status(service, result) do
      :success -> {:ok, result}
      :failure -> {:error, result}
    end
  end
end
