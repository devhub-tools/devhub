defmodule Devhub.Workflows.Actions.DeleteWorkflow do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Workflow

  @callback delete_workflow(Workflow.t()) :: {:ok, Workflow.t()} | {:error, Ecto.Changeset.t()}
  def delete_workflow(workflow) do
    Repo.delete(workflow)
  end
end
