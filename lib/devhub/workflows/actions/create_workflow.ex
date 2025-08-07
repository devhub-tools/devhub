defmodule Devhub.Workflows.Actions.CreateWorkflow do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Workflow

  @callback create_workflow(map()) :: {:ok, Workflow.t()} | {:error, Ecto.Changeset.t()}
  def create_workflow(params) do
    params
    |> Workflow.changeset()
    |> Repo.insert()
  end
end
