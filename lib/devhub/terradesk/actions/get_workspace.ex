defmodule Devhub.TerraDesk.Actions.GetWorkspace do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback get_workspace(Keyword.t(), Keyword.t()) :: {:ok, Workspace.t()} | {:error, :workspace_not_found}
  def get_workspace(by, opts) do
    preload =
      [:organization, :env_vars, :secrets, :workload_identity, :repository, :permissions] ++
        Keyword.get(opts, :preload, [])

    case Repo.get_by(Workspace, by) do
      %Workspace{} = workspace -> {:ok, Repo.preload(workspace, preload)}
      nil -> {:error, :workspace_not_found}
    end
  end
end
