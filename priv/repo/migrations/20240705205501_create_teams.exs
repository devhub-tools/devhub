defmodule Devhub.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :organization_id, references(:organizations), null: false
      add :name, :string

      timestamps()
    end

    create unique_index(:teams, [:organization_id, :name])

    create table(:team_members) do
      add :team_id, references(:teams), null: false
      add :organization_user_id, references(:organization_users), null: false

      timestamps()
    end

    create unique_index(:team_members, [:team_id, :organization_user_id])
  end
end
