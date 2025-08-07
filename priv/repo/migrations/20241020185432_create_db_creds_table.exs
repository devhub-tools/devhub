defmodule Devhub.Repo.Migrations.CreateDbCredsTable do
  use Ecto.Migration

  def change do
    create table(:querydesk_database_credentials) do
      add :username, :text, null: false
      add :password, :binary, null: false
      add :reviews_required, :integer, null: false
      add :database_id, references(:querydesk_databases), null: false
      add :default_credential, :boolean, null: false, default: false
      add :archived_at, :utc_datetime

      timestamps()
    end

    create unique_index(:querydesk_database_credentials, [:database_id, :username],
             where: "archived_at IS NULL"
           )

    create unique_index(:querydesk_database_credentials, [:database_id, :default_credential],
             name: :unique_default_credential,
             where: "default_credential = TRUE"
           )
  end
end
