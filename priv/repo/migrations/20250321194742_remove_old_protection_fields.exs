defmodule Devhub.Repo.Migrations.RemoveOldProtectionFields do
  use Ecto.Migration

  def change do
    execute "DROP VIEW IF EXISTS querydesk_active_databases"

    alter table(:querydesk_databases) do
      remove :enable_data_protection
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL"

    alter table(:querydesk_queries) do
      remove :bypass_data_protection
    end
  end
end
