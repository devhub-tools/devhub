defmodule Devhub.Integrations.Linear.Actions.UpsertProject do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.Project
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback upsert_project(Integration.t(), map()) :: {:ok, Project.t()} | {:error, Ecto.Changeset.t()}
  def upsert_project(integration, project) do
    %{
      organization_id: integration.organization_id,
      archived_at: project["archivedAt"],
      canceled_at: project["canceledAt"],
      completed_at: project["completedAt"],
      created_at: project["createdAt"],
      external_id: project["id"],
      name: project["name"],
      status: project["status"]["name"]
    }
    |> Project.changeset()
    |> Repo.insert(
      on_conflict:
        {:replace,
         [
           :archived_at,
           :canceled_at,
           :completed_at,
           :created_at,
           :name,
           :status
         ]},
      conflict_target: [:organization_id, :external_id],
      returning: true
    )
  end
end
