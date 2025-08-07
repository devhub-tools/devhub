defmodule Devhub.Repo.Migrations.EnableDatabaseAutosave do
  use Ecto.Migration

  def change do
    # credentials
    execute "DROP VIEW IF EXISTS querydesk_active_database_credentials",
            "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL"

    alter table(:querydesk_database_credentials) do
      modify :username, :text, null: true, from: :text
      modify :password, :binary, null: true, from: :binary
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL",
            "DROP VIEW IF EXISTS querydesk_active_database_credentials"

    # databases
    execute "DROP VIEW IF EXISTS querydesk_active_databases",
            "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL"

    alter table(:querydesk_databases) do
      modify :name, :text, null: true, from: :text
      modify :hostname, :text, null: true, from: :text
      modify :database, :text, null: true, from: :text
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL",
            "DROP VIEW IF EXISTS querydesk_active_databases"

    drop unique_index(:querydesk_databases, [:organization_id, :name, :group],
           where: "archived_at IS NULL"
         )

    create unique_index(:querydesk_databases, [:organization_id, :name, :group],
             where: "archived_at IS NULL and name IS NOT NULL",
             nulls_distinct: false
           )
  end
end
