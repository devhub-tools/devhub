defmodule Devhub.Repo.Migrations.CreateQueriesTable do
  use Ecto.Migration

  def change do
    create table(:querydesk_queries) do
      add :organization_id, references(:organizations), null: false
      add :user_id, references(:users), null: false
      add :credential_id, references(:querydesk_database_credentials), null: false
      add :query, :text, null: false
      add :failed, :boolean, null: false, default: false
      add :is_system, :boolean, null: false, default: false
      add :executed_at, :utc_datetime_usec

      timestamps()
    end

    create index(:querydesk_queries, [:user_id])

    create table(:querydesk_query_approvals) do
      add :query_id, references(:querydesk_queries), null: false
      add :approving_user_id, references(:users), null: false
      add :approved_at, :utc_datetime_usec, null: false
    end

    create index(:querydesk_query_approvals, [:query_id])
    create unique_index(:querydesk_query_approvals, [:approving_user_id, :query_id])
  end
end
