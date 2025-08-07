defmodule Devhub.Repo.Migrations.CreateDatabasesTable do
  use Ecto.Migration

  def change do
    create table(:querydesk_databases) do
      add :api_id, :text
      add :name, :text, null: false
      add :adapter, :text, null: false
      add :hostname, :text, null: false
      add :database, :text, null: false
      add :ssl, :boolean, null: false, default: false
      add :cacertfile, :binary
      add :keyfile, :binary
      add :certfile, :binary
      add :organization_id, references(:organizations), null: false
      add :agent_id, references(:agents)
      add :restrict_access, :boolean, null: false, default: false
      add :enable_data_protection, :boolean, null: false, default: false
      add :slack_webhook_url, :text
      add :slack_channel, :text
      add :group, :text

      timestamps()
    end
  end
end
