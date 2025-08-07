defmodule Devhub.Repo.Migrations.CreateColumnsTable do
  use Ecto.Migration

  def change do
    create table(:querydesk_database_columns) do
      add :organization_id, references(:organizations), null: false
      add :database_id, references(:querydesk_databases), null: false
      add :name, :text, null: false
      add :table, :text, null: false
      add :type, :text, null: false
      add :data_protection_action, :text, null: false, default: "hide"
      add :fkey_column_name, :text
      add :fkey_table_name, :text
      add :is_primary_key, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:querydesk_database_columns, [:database_id, :table, :name])
  end
end
