defmodule Devhub.Repo.Migrations.UpsertCommits do
  use Ecto.Migration

  def change do
    alter table(:commits) do
      modify :authored_at, :utc_datetime, null: true, from: :utc_datetime
    end
  end
end
