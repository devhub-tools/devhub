defmodule Devhub.Users.Actions.GetTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Team

  @callback get_team(String.t()) :: {:ok, Team.t()} | {:error, :team_not_found}
  def get_team(id) do
    case Repo.get(Team, id) do
      %Team{} = team -> {:ok, team}
      _error -> {:error, :team_not_found}
    end
  end
end
