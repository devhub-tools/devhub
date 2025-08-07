defmodule Devhub.Repo.Migrations.UserPinnedDatabases do
  use Ecto.Migration

  def change do
    create table(:user_pinned_databases) do
      add :organization_user_id, references(:organization_users, on_delete: :delete_all),
        null: false

      add :database_id, references(:querydesk_databases, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
