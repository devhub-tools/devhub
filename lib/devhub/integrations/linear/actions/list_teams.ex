defmodule Devhub.Integrations.Linear.Actions.ListTeams do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.Linear.Team
  alias Devhub.Repo

  @callback list_teams(String.t()) :: [Team.t()]
  def list_teams(organization_id) do
    query =
      from t in Team,
        where: t.organization_id == ^organization_id,
        order_by: fragment("LOWER(?)", t.name)

    Repo.all(query)
  end
end
