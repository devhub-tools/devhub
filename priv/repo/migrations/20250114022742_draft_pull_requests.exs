defmodule Devhub.Repo.Migrations.DraftPullRequests do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      add :is_draft, :boolean, default: false, null: false
    end
  end
end
