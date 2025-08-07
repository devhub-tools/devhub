defmodule Devhub.Users.Actions.RemoveFromTeam do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.TeamMember

  @callback remove_from_team(String.t(), String.t()) :: {non_neg_integer(), nil | term()}
  def remove_from_team(organization_user_id, team_id) do
    query =
      from tm in TeamMember,
        where: tm.organization_user_id == ^organization_user_id,
        where: tm.team_id == ^team_id

    Repo.delete_all(query)
  end
end
