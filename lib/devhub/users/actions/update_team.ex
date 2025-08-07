defmodule Devhub.Users.Actions.UpdateTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Team

  @callback update_team(Team.t(), map()) ::
              {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def update_team(team, params) do
    team
    |> Team.changeset(params)
    |> Repo.update()
  end
end
