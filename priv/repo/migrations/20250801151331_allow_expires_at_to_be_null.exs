defmodule Devhub.Repo.Migrations.AllowExpiresAtToBeNull do
  use Ecto.Migration

  def change do
    alter table(:querydesk_shared_queries) do
      modify :expires_at, :utc_datetime, null: true
    end
  end
end
