defmodule Devhub.Repo.Migrations.CredentialHostnameOverride do
  use Ecto.Migration

  def change do
    execute "DROP VIEW IF EXISTS querydesk_active_database_credentials",
            "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL"

    alter table(:querydesk_database_credentials) do
      add :hostname, :string
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL",
            "DROP VIEW IF EXISTS querydesk_active_database_credentials"
  end
end
