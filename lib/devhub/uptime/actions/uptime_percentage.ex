defmodule Devhub.Uptime.Actions.UptimePercentage do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.CheckSummary

  @callback uptime_percentage(String.t(), String.t()) :: float()
  def uptime_percentage(service_id, duration) do
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
        select: type(fragment("1.0 * COUNT(*) FILTER (WHERE ? = 'success') / NULLIF(COUNT(1), 0)", c.status), :float)

    Repo.one(query) || 0.0
  end

  defp calculate(service_id, %Date{} = since) do
    query =
      from c in CheckSummary,
        where: c.service_id == ^service_id,
        where: c.date >= ^since,
        select: type(avg(c.success_percentage), :float)

    Repo.one(query) || calculate(service_id, Timex.to_datetime(since))
  end
end
