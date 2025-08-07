defmodule Devhub.Repo.Migrations.OrgnizationLicense do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :license, :map
    end

    execute "UPDATE organizations SET license = jsonb_build_object('key', license_key, 'plan', license_plan, 'renew', license_renew, 'expires_at', license_expires_at)",
            ""
  end
end
