defmodule Devhub.TerraDesk.Actions.DeleteWorkspace do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback delete_workspace(Workspace.t()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def delete_workspace(workspace) do
    Repo.delete(workspace, allow_stale: true)
  end
end
