defmodule Devhub.Repo.Migrations.QuerydeskSavedQueries do
  use Ecto.Migration

  def change do
    create table(:querydesk_saved_queries) do
      add :organization_id, references(:organizations), null: false
      add :title, :string, null: false
      add :query, :text, null: false

      timestamps()
    end
  end
end
