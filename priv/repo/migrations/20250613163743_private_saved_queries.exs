defmodule Devhub.Repo.Migrations.PrivateSavedQueries do
  use Ecto.Migration

  def change do
    alter table(:querydesk_saved_queries) do
      add :private, :boolean, default: false, null: false
      add :created_by_user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
