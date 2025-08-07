defmodule Devhub.Uptime.Actions.Latency do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.CheckSummary

  @callback latency(String.t(), String.t()) :: float()
  def latency(service_id, duration) do
    since =
      case Integer.parse(duration) do
        {hours, "h"} -> Timex.shift(DateTime.utc_now(), hours: -hours)
        {days, "d"} -> Date.add(Date.utc_today(), -days)
        {months, "m"} -> Date.add(Date.utc_today(), -(months * 30))
      end

    calculate(service_id, since) || +0.0
  end

  defp calculate(service_id, %DateTime{} = since) do
    query =
      from c in Check,
        where: c.service_id == ^service_id,
        where: c.inserted_at >= ^since,
        select: avg(c.request_time)

    query |> Repo.one() |> Kernel.||(0) |> Decimal.round(0) |> Decimal.to_integer()
  end

  defp calculate(service_id, %Date{} = since) do
    query =
      from c in CheckSummary,
        where: c.service_id == ^service_id,
        where: c.date >= ^since,
        select: avg(c.avg_request_time)

    query
    |> Repo.one()
    |> Kernel.||(calculate(service_id, Timex.to_datetime(since)))
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end
end
