defmodule Devhub.Integrations.Linear.Actions.ListLabels do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Repo

  @callback list_labels(String.t()) :: [Label.t()]
  def list_labels(organization_id) do
    query =
      from l in Label,
        left_join: t in assoc(l, :team),
        where: l.organization_id == ^organization_id,
        order_by: [{:asc_nulls_first, t.name}, fragment("LOWER(?)", l.name)],
        preload: [team: t]

    Repo.all(query)
  end
end
