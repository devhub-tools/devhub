defmodule Devhub.Repo.Migrations.AddTeamToLinearTeam do
  use Ecto.Migration

  def change do
    alter table(:linear_teams) do
      add :team_id, references(:teams)
    end
  end
end
