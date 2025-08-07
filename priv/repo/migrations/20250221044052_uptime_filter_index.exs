defmodule Devhub.Repo.Migrations.UptimeFilterIndex do
  use Ecto.Migration

  def change do
    drop index(:uptime_checks, [:service_id, :inserted_at])

    create_if_not_exists index(:uptime_checks, [:service_id, :inserted_at, :status, :request_time])
  end
end
