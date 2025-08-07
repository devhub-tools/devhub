defmodule Devhub.Integrations.Linear.Jobs.Import do
  @moduledoc false
  use Oban.Worker, queue: :linear

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = args, priority: priority}) do
    days_to_sync = Map.get(args, "days_to_sync", 30)
    integration = Repo.get!(Integration, id)

    if priority == 0 do
      broadcast_status(integration.organization_id, "Importing users", 0)
    end

    Linear.import_users(integration)

    if priority == 0 do
      broadcast_status(integration.organization_id, "Importing projects", 25)
    end

    Linear.import_projects(integration, "-P#{days_to_sync}D")

    if priority == 0 do
      broadcast_status(integration.organization_id, "Importing labels", 50)
    end

    Linear.import_labels(integration)

    if priority == 0 do
      broadcast_status(integration.organization_id, "Importing issues", 75)
    end

    Linear.import_issues(integration, "-P#{days_to_sync}D")

    if priority == 0 do
      broadcast_status(integration.organization_id, "Import done", 100)
    end

    :ok
  end

  defp broadcast_status(organization_id, message, percentage) do
    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "linear_sync:#{organization_id}",
      {:import_status, %{message: message, percentage: percentage}}
    )
  end
end
