defmodule Devhub.Repo.Migrations.DatabaseProtectionActions do
  use Ecto.Migration

  def change do
    create table(:querydesk_database_protection_actions) do
      add :database_id, references(:querydesk_databases)
      add :name, :text
      add :table, :text
      add :action, :text
      add :condition, :text
      add :join_through, :text

      timestamps()
    end

    create index(:querydesk_database_protection_actions, [:database_id])

    alter table(:querydesk_database_columns) do
      add :custom_protection_action_id, references(:querydesk_database_protection_actions)
    end
  end
end
