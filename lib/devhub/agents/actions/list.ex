defmodule Devhub.Agents.Actions.List do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.Repo

  @callback list(String.t()) :: [Agent.t()]
  def list(organization_id) do
    query =
      from a in Agent,
        where: a.organization_id == ^organization_id,
        order_by: [asc: a.name]

    Repo.all(query)
  end
end
