defmodule Devhub.Workflows.Actions.ListWorkflows do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Workflows.Schemas.Workflow

  @callback list_workflows(String.t(), Keyword.t()) :: [%Workflow{}]
  def list_workflows(organization_id, filters) do
    query =
      from d in Workflow,
        where: d.organization_id == ^organization_id,
        order_by: [asc: d.name]

    query
    |> query_filter(filters)
    |> Repo.all()
  end
end
