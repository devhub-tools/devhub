defmodule Devhub.Repo.Migrations.QuerydeskSharedQueries do
  use Ecto.Migration

  def change do
    create table(:querydesk_shared_queries) do
      add :database_id, references(:querydesk_databases, on_delete: :delete_all), null: false
      add :created_by_user_id, references(:users, on_delete: :delete_all), null: false
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :query, :text, null: false
      add :results, :binary
      add :include_results, :boolean, null: false
      add :restricted_access, :boolean, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps()
    end

    alter table(:object_permissions) do
      add :shared_query_id, references(:querydesk_shared_queries, on_delete: :delete_all)
    end

    create unique_index(:object_permissions, [:shared_query_id, :organization_user_id],
             where: "shared_query_id IS NOT NULL and organization_user_id IS NOT NULL"
           )

    create unique_index(:object_permissions, [:shared_query_id, :role_id],
             where: "shared_query_id IS NOT NULL and role_id IS NOT NULL"
           )
  end
end
