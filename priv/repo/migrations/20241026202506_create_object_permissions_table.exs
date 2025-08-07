defmodule Devhub.Repo.Migrations.CreateObjectPermissionsTable do
  use Ecto.Migration

  def change do
    create table(:object_permissions) do
      add :organization_user_id, references(:organization_users), null: false
      add :permission, :text, null: false
      add :database_id, references(:querydesk_databases)

      timestamps()
    end

    create unique_index(:object_permissions, [:database_id, :organization_user_id])
  end
end
