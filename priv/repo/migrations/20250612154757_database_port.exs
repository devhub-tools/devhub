defmodule Devhub.Repo.Migrations.DatabasePort do
  use Ecto.Migration

  def change do
    execute "DROP VIEW IF EXISTS querydesk_active_databases"

    alter table(:querydesk_databases) do
      add :port, :integer
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL"
  end
end
