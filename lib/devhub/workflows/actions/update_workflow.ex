defmodule Devhub.Workflows.Actions.UpdateWorkflow do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Workflow

  @callback update_workflow(Workflow.t(), map()) ::
              {:ok, Workflow.t()} | {:error, Ecto.Changeset.t()}
  def update_workflow(workflow, params) do
    workflow
    |> Workflow.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, workflow} -> {:ok, Repo.preload(workflow, steps: [permissions: [organization_user: :user]])}
      error -> error
    end
  end
end
