defmodule Devhub.Users.Actions.ListTeams do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.Team

  @callback list_teams(String.t()) :: [Team.t()]
  def list_teams(organization_id) do
    query =
      from t in Team,
        where: t.organization_id == ^organization_id,
        order_by: :name

    Repo.all(query)
  end
end
