defmodule Devhub.Repo.Migrations.UpdateChecksIndex do
  use Ecto.Migration

  def change do
    create index(:uptime_checks, [:service_id, :inserted_at])
    drop index(:uptime_checks, [:service_id])
    drop index(:uptime_checks, [:inserted_at])
  end
end
