defmodule Devhub.Repo.Migrations.SlackMessageTs do
  use Ecto.Migration

  def up do
    alter table(:querydesk_queries) do
      add :slack_channel, :string
      add :slack_message_ts, :string
    end

    execute "DROP VIEW IF EXISTS querydesk_active_databases"

    alter table(:querydesk_databases) do
      remove :slack_webhook_url
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL"
  end

  def down do
    alter table(:querydesk_queries) do
      remove :slack_channel, :string
      remove :slack_message_ts
    end

    execute "DROP VIEW IF EXISTS querydesk_active_databases"

    alter table(:querydesk_databases) do
      add :slack_webhook_url, :string
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_databases AS SELECT * FROM querydesk_databases WHERE archived_at IS NULL"
  end
end
