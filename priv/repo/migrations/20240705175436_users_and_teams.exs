defmodule Devhub.Repo.Migrations.UsersAndTeams do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :text, null: false
      add :picture, :text
      add :external_id, :text, null: false
      add :provider, :text, null: false
      add :timezone, :text, default: "America/Denver", null: false

      timestamps()
    end

    create unique_index(:users, [:provider, :external_id])

    create table(:organizations) do
      add :name, :text

      timestamps()
    end

    create table(:organization_users) do
      add :organization_id, references(:organizations), null: false
      add :user_id, references(:users)
      add :permissions, :map, default: %{}, null: false
      add :legal_name, :text

      timestamps()
    end

    create unique_index(:organization_users, [:organization_id, :user_id])
  end
end
