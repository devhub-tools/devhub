defmodule Devhub.Repo.Migrations.LicensePlan do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :license_plan, :string, default: "enterprise"
    end
  end
end
