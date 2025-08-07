defmodule Devhub.TerraDesk.Actions.GetWorkspaces do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Schemas.Workspace

  @callback get_workspaces(Keyword.t()) :: [Workspace.t()]
  def get_workspaces(filters) do
    ranking_query =
      from p in Plan,
        select: %{id: p.id, row_number: over(row_number(), :plans_partition)},
        windows: [plans_partition: [partition_by: :workspace_id, order_by: [desc: p.inserted_at]]],
        join: w in assoc(p, :workspace),
        join: r in assoc(w, :repository),
        where: p.github_branch == r.default_branch

    latest_plan_query =
      from p in Plan,
        join: r in subquery(ranking_query),
        on: p.id == r.id and r.row_number == 1

    query =
      from w in Workspace,
        order_by: w.name,
        preload: [:organization, :repository, latest_plan: ^latest_plan_query]

    query
    |> query_filter(filters)
    |> Repo.all()
  end
end
