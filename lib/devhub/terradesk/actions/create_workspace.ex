defmodule Devhub.TerraDesk.Actions.CreateWorkspace do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback create_workspace(map()) :: {:ok, Workspace.t()} | {:error, Ecto.Changeset.t()}
  def create_workspace(params) do
    params
    |> Workspace.changeset()
    |> Repo.insert()
  end
end
