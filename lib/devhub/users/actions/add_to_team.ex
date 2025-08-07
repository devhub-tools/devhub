defmodule Devhub.Users.Actions.AddToTeam do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.TeamMember

  @callback add_to_team(String.t(), String.t()) :: {:ok, TeamMember.t()} | {:error, Ecto.Changeset.t()}
  def add_to_team(organization_user_id, team_id) do
    %TeamMember{}
    |> TeamMember.changeset(%{
      organization_user_id: organization_user_id,
      team_id: team_id
    })
    |> Repo.insert()
  end
end
