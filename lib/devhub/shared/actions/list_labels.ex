defmodule Devhub.Shared.Actions.ListLabels do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Shared.Schemas.Label

  @callback list_labels(String.t()) :: [Label.t()]
  def list_labels(organization_id) do
    query =
      from l in Label,
        where: l.organization_id == ^organization_id,
        order_by: [asc: :name]

    Repo.all(query)
  end
end
