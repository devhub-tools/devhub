defmodule Devhub.Repo.Migrations.CreateDashboardsTable do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:dashboards) do
      add :organization_id, references(:organizations), null: false
      add :name, :text, null: false
      add :archived_at, :utc_datetime, null: true

      timestamps()
    end

    create unique_index(:dashboards, [:organization_id, :name], where: "archived_at IS NULL")
  end
end
