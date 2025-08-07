defmodule Devhub.Integrations.Linear.ImportCron do
  @moduledoc false
  use Oban.Worker, queue: :linear

  import Ecto.Query

  alias Devhub.Integrations.Linear.Jobs.Import
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @impl Oban.Worker
  def perform(_job) do
    query =
      from i in Integration,
        where: i.provider == :linear

    query
    |> Repo.all()
    |> Enum.each(fn integration ->
      %{id: integration.id, days_to_sync: 2} |> Import.new(priority: 9) |> Oban.insert()
    end)
  end
end
