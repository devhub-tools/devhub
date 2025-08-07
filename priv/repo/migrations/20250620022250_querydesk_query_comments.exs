defmodule Devhub.Repo.Migrations.QuerydeskQueryComments do
  use Ecto.Migration

  def change do
    create table(:querydesk_query_comments) do
      add :query_id, references(:querydesk_queries, on_delete: :delete_all), null: false
      add :created_by_user_id, references(:users), null: false
      add :organization_id, references(:organizations), null: false
      add :comment, :text

      timestamps()
    end
  end
end
