defmodule Devhub.Uptime.Jobs.SummarizeChecks do
  @moduledoc false
  use Oban.Worker, queue: :uptime

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.CheckSummary

  def perform(%Oban.Job{args: %{"service_id" => service_id} = args}) do
    days = args["days"] || 1

    checks =
      Enum.flat_map(0..days, fn day ->
        date = Date.add(Date.utc_today(), -day)

        service_id
        |> get_checks_within_range(date)
        |> Enum.map(fn check ->
          check |> Map.put(:id, UXID.generate!(prefix: "chk_sum")) |> Map.put(:service_id, service_id)
        end)
      end)

    Repo.insert_all(
      CheckSummary,
      checks,
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: [:service_id, :date]
    )

    :ok
  end

  defp get_checks_within_range(service_id, date) do
    since = date |> Timex.to_datetime() |> Timex.beginning_of_day()
    until = Timex.end_of_day(since)

    # TODO: timezone
    # TODO: missing data points
    query =
      from c in Check,
        select: %{
          date: type(c.inserted_at, :date),
          success_percentage: fragment("1.0 * COUNT(*) FILTER (WHERE ? = 'success') / NULLIF(COUNT(1), 0)", c.status),
          avg_dns_time: sum(c.dns_time * c.time_since_last_check) / sum(c.time_since_last_check),
          avg_connect_time: sum((c.connect_time - c.dns_time) * c.time_since_last_check) / sum(c.time_since_last_check),
          avg_tls_time: sum((c.tls_time - c.connect_time) * c.time_since_last_check) / sum(c.time_since_last_check),
          avg_first_byte_time:
            sum((c.first_byte_time - c.tls_time) * c.time_since_last_check) / sum(c.time_since_last_check),
          avg_to_finish:
            sum((c.request_time - c.first_byte_time) * c.time_since_last_check) / sum(c.time_since_last_check),
          avg_request_time: sum(c.request_time * c.time_since_last_check) / sum(c.time_since_last_check)
        },
        where: c.service_id == ^service_id,
        where: c.inserted_at >= ^since,
        where: c.inserted_at <= ^until,
        group_by: 1

    Repo.all(query)
  end
end
