defmodule Devhub.Users.Actions.DeleteTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Team

  @callback delete_team(Team.t()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def delete_team(team) do
    Repo.delete(team)
  end
end
