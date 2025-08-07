defmodule Devhub.Uptime.Jobs.Cron do
  @moduledoc false
  use Oban.Worker, queue: :uptime

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Jobs.SummarizeChecks
  alias Devhub.Uptime.Schemas.Check
  alias Devhub.Uptime.Schemas.Service

  def perform(_args) do
    from(s in Service, select: s.id)
    |> Repo.all()
    |> Enum.each(fn id ->
      %{service_id: id}
      |> SummarizeChecks.new()
      |> Oban.insert()

      cleanup_data(id)
    end)
  end

  defp cleanup_data(service_id) do
    query =
      from c in Check,
        where: c.service_id == ^service_id,
        where: c.status == :success,
        where: c.inserted_at < ^Timex.shift(DateTime.utc_now(), days: -7),
        where: c.inserted_at > ^Timex.shift(DateTime.utc_now(), days: -10)

    Repo.update_all(query, set: [response_body: nil, response_headers: nil])
  end
end
