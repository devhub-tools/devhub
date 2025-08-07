defmodule Devhub.Uptime.CheckJob do
  @moduledoc false
  use Oban.Worker,
    queue: :uptime,
    unique: [keys: [:id], period: :infinity, states: [:scheduled, :available, :retryable]]

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Service

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = args, scheduled_at: scheduled_at}) do
    started_at = DateTime.utc_now()

    case Uptime.get_service(id: id) do
      {:ok, %Service{enabled: true} = service} ->
        case Uptime.trace_request(service) do
          {:ok, result} ->
            Uptime.save_check!(%{
              organization_id: service.organization_id,
              service_id: service.id,
              status: Service.status(service, result),
              status_code: result.status_code,
              response_body: result.response_body,
              dns_time: result.dns_done,
              connect_time: result.connect_done,
              tls_time: result.tls_done,
              first_byte_time: result.first_byte_received,
              request_time: result.complete,
              time_since_last_check: time_since_last_check(service, args, started_at),
              response_headers:
                Enum.map(result.response_headers, fn %{key: key, value: value} ->
                  %{key: key, value: value}
                end)
            })

          {:error, :timeout} ->
            Uptime.save_check!(%{
              organization_id: service.organization_id,
              service_id: service.id,
              status: :timeout,
              time_since_last_check: time_since_last_check(service, args, started_at)
            })
        end

        schedule_at = DateTime.add(scheduled_at, service.interval_ms, :millisecond)

        schedule_at =
          if DateTime.before?(schedule_at, started_at) do
            DateTime.add(started_at, service.interval_ms, :millisecond)
          else
            schedule_at
          end

        {:ok, _job} =
          %{id: id, previous_started_at: started_at}
          |> Devhub.Uptime.CheckJob.new(scheduled_at: schedule_at)
          |> Oban.insert()

        :ok

      _service ->
        :ok
    end

    :ok
  end

  defp time_since_last_check(service, args, started_at) do
    case args["previous_started_at"] do
      nil ->
        service.interval_ms

      previous_started_at ->
        {:ok, previous_started_at, 0} = DateTime.from_iso8601(previous_started_at)

        DateTime.diff(started_at, previous_started_at, :millisecond)
    end
  end
end
