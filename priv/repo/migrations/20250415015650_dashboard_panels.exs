defmodule Devhub.Repo.Migrations.DashboardPanels do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      add :panels, :map
    end
  end
end
