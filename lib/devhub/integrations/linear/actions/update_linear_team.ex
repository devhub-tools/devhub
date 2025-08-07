defmodule Devhub.Integrations.Linear.Actions.UpdateLinearTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.Team
  alias Devhub.Repo

  @callback update_linear_team(Team.t(), map()) :: {:ok, Team.t()} | {:error, Ecto.Changeset.t()}
  def update_linear_team(team, params) do
    team
    |> Team.changeset(params)
    |> Repo.update()
  end
end
