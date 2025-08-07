defmodule Devhub.Repo.Migrations.CredentialPosition do
  use Ecto.Migration

  def change do
    alter table(:querydesk_database_credentials) do
      add :position, :integer
    end

    execute "CREATE OR REPLACE VIEW querydesk_active_database_credentials AS SELECT * FROM querydesk_database_credentials WHERE archived_at IS NULL",
            ""
  end
end
