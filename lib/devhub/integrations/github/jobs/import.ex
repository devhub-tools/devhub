defmodule Devhub.Integrations.GitHub.Jobs.Import do
  @moduledoc false
  use Oban.Worker, queue: :github

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Jobs.ImportRepository

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"organization_id" => organization_id} = args, priority: priority}) do
    days_to_sync = Map.get(args, "days_to_sync", 30)
    {:ok, integration} = Integrations.get_by(organization_id: organization_id, provider: :github)

    GitHub.import_users(integration)
    GitHub.import_repositories(integration)
    since = Date.add(Date.utc_today(), -days_to_sync)

    repositories =
      organization_id
      |> GitHub.list_repositories()
      |> Enum.filter(& &1.enabled)

    total = length(repositories)

    repositories
    |> Enum.with_index()
    |> Enum.each(fn {repository, index} ->
      %{repository_id: repository.id, since: since, index: index, total: total}
      |> ImportRepository.new(priority: priority)
      |> Oban.insert()
    end)

    :ok
  end
end
