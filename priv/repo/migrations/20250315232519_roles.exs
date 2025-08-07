defmodule Devhub.Repo.Migrations.Roles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :organization_id, references(:organizations), null: false
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create unique_index(:roles, [:organization_id, :name])

    create table(:organization_users_roles) do
      add :organization_user_id, references(:organization_users), null: false
      add :role_id, references(:roles, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:organization_users_roles, [:organization_user_id, :role_id])

    alter table(:object_permissions) do
      add :role_id, references(:roles, on_delete: :delete_all)
      modify :organization_user_id, :text, null: true, from: :text
    end
  end
end
