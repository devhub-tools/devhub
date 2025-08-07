defmodule Devhub.Repo.Migrations.DashboardPermissions do
  use Ecto.Migration

  def change do
    alter table(:object_permissions) do
      add :dashboard_id, references(:dashboards, on_delete: :delete_all)
    end

    create unique_index(:object_permissions, [:dashboard_id, :organization_user_id],
             where: "dashboard_id IS NOT NULL"
           )
  end
end
