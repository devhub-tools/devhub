defmodule Devhub.Integrations.GitHub.Jobs.ImportRepository do
  @moduledoc false
  use Oban.Worker, queue: :github

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub

  @impl Oban.Worker
  # we use priority to only broadcast for highest priority which means we have a user potentially watching the status
  def perform(%Oban.Job{
        args: %{"repository_id" => id, "since" => since, "index" => index, "total" => total},
        priority: priority
      }) do
    {:ok, since} = Date.from_iso8601(since)

    with {:ok, %{enabled: true} = repository} <- GitHub.get_repository(id: id) do
      if priority == 0 do
        broadcast_status(
          repository.organization_id,
          "Importing #{repository.owner}/#{repository.name}",
          index / total * 100
        )
      end

      {:ok, integration} =
        Integrations.get_by(organization_id: repository.organization_id, provider: :github)

      GitHub.import_default_branch(integration, repository, since: since)

      if priority == 0 do
        broadcast_status(
          repository.organization_id,
          "Importing #{repository.owner}/#{repository.name}",
          (index + 0.5) / total * 100
        )
      end

      GitHub.import_pull_requests(integration, repository, since: since)

      if index + 1 == total and priority == 0 do
        broadcast_status(repository.organization_id, "Import done", 100)
      end
    end

    :ok
  end

  defp broadcast_status(organization_id, message, percentage) do
    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "github_sync:#{organization_id}",
      {:import_status, %{message: message, percentage: percentage}}
    )
  end
end
