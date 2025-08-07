defmodule Devhub.Integrations.GitHub.ImportCron do
  @moduledoc false
  use Oban.Worker, queue: :github

  alias Devhub.Integrations.GitHub.Jobs.Import
  alias Devhub.Integrations.GitHub.Storage

  @impl Oban.Worker
  def perform(_job) do
    Enum.each(Storage.all_integrations(), fn integration ->
      %{organization_id: integration.organization_id} |> Import.new(priority: 9) |> Oban.insert()
    end)
  end
end
