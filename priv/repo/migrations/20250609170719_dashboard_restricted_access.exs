defmodule Devhub.Repo.Migrations.DashboardRestrictedAccess do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      add :restricted_access, :boolean, null: false, default: true
    end
  end
end
