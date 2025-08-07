defmodule Devhub.Repo.Migrations.ArchivedAt do
  use Ecto.Migration

  def change do
    alter table(:querydesk_databases) do
      add :archived_at, :utc_datetime
    end

    execute """
            CREATE OR REPLACE RULE soft_delete_databases AS ON DELETE TO querydesk_databases
            DO INSTEAD UPDATE querydesk_databases SET archived_at = NOW() WHERE id = OLD.id AND archived_at IS NULL;
            """,
            """
            DROP RULE IF EXISTS soft_delete_databases ON querydesk_databases;
            """

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL",
            "DROP VIEW IF EXISTS querydesk_active_databases"

    execute """
            CREATE OR REPLACE RULE soft_delete_credentials AS ON DELETE TO querydesk_database_credentials
            DO INSTEAD UPDATE querydesk_database_credentials SET archived_at = NOW() WHERE id = OLD.id AND archived_at IS NULL;
            """,
            """
            DROP RULE IF EXISTS soft_delete_credentials ON querydesk_database_credentials;
            """

    execute "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL",
            "DROP VIEW IF EXISTS querydesk_active_database_credentials"
  end
end
