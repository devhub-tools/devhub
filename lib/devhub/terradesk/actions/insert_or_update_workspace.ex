defmodule Devhub.TerraDesk.Actions.InsertOrUpdateWorkspace do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback insert_or_update_workspace(Workspace.t(), map()) ::
              {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_workspace(workspace, params) do
    workspace
    |> Workspace.changeset(params)
    |> Repo.insert_or_update()
  end
end
