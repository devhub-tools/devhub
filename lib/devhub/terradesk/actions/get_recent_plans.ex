defmodule Devhub.TerraDesk.Actions.GetRecentPlans do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Plan

  @callback get_recent_plans(Workspace.t()) :: [Plan.t()]
  def get_recent_plans(workspace) do
    query =
      from p in Plan,
        where: p.workspace_id == ^workspace.id,
        where: p.status != :canceled,
        order_by: [desc: p.inserted_at],
        preload: [:user],
        limit: 100

    Repo.all(query)
  end
end
