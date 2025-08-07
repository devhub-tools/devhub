defmodule Devhub.Calendar.SyncJob do
  @moduledoc false
  use Oban.Worker, queue: :calendar

  import Ecto.Query

  alias Devhub.Calendar
  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Repo

  @impl Oban.Worker
  def perform(_args) do
    from(i in Ical)
    |> Repo.all()
    |> Enum.each(&Calendar.sync/1)
  end
end
