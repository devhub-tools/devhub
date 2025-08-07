defmodule Devhub.Repo.Migrations.CreateChecksTable do
  use Ecto.Migration

  def change do
    create table(:uptime_checks) do
      add :organization_id, references(:organizations), null: false
      add :service_id, references(:uptime_services), null: false
      add :status_code, :integer
      add :response_body, :binary
      add :dns_time, :integer
      add :connect_time, :integer
      add :tls_time, :integer
      add :first_byte_time, :integer
      add :request_time, :integer
      add :status, :text, NULL: false, default: "pending"
      add :time_since_last_check, :bigint, null: false

      timestamps()
    end

    create index(:uptime_checks, [:service_id])
    create index(:uptime_checks, [:inserted_at])
  end
end
