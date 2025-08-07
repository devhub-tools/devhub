defmodule Devhub.Repo.Migrations.Licensing do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :license_key, :text
      add :license_expires_at, :utc_datetime
      add :license_renew, :boolean, default: false, null: false
    end
  end
end
