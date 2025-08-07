defmodule Devhub.Repo.Migrations.CreateServicesTable do
  use Ecto.Migration

  def change do
    create table(:uptime_services) do
      add :organization_id, references(:organizations), null: false
      add :name, :text, null: false
      add :method, :text
      add :url, :text
      add :expected_status_code, :text
      add :expected_response_body, :text
      add :interval_ms, :integer, default: 60000, null: false
      add :timeout_ms, :integer, default: 5000, null: false
      add :enabled, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:uptime_services, [:name])
  end
end
