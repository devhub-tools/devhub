defmodule Devhub.Repo.Migrations.AllowPrOpenedAtToBeNull do
  use Ecto.Migration

  def change do
    alter table(:pull_requests) do
      modify :opened_at, :utc_datetime, null: true
    end
  end
end
