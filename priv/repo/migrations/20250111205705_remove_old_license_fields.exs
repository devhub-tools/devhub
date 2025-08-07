defmodule Devhub.Repo.Migrations.RemoveOldLicenseFields do
  use Ecto.Migration

  def up do
    alter table(:organizations) do
      add :installation_id, :text
      add :private_key, :binary
      remove :license_key
      remove :license_expires_at
      remove :license_plan
      remove :license_renew
    end
  end

  def down do
    alter table(:organizations) do
      remove :private_key
      remove :installation_id
      add :license_key, :text
      add :license_expires_at, :utc_datetime
      add :license_plan, :string
      add :license_renew, :boolean
    end
  end
end
