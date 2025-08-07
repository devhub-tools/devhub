defmodule Devhub.Workflows.Actions.GetWorkflow do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Workflow

  @callback get_workflow(Keyword.t()) :: {:ok, Workflow.t()} | {:error, :workflow_not_found}
  def get_workflow(by) do
    case Repo.get_by(Workflow, by) do
      %Workflow{} = workflow ->
        {:ok, Repo.preload(workflow, [:trigger_linear_label, steps: [permissions: [:role, organization_user: :user]]])}

      nil ->
        {:error, :workflow_not_found}
    end
  end
end
