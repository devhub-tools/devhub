defmodule Devhub.Repo.Migrations.UptimeCheckSummaries do
  use Ecto.Migration

  def change do
    create table(:uptime_check_summaries) do
      add :service_id, references(:uptime_services), null: false
      add :date, :date, null: false
      add :success_percentage, :decimal
      add :avg_dns_time, :decimal
      add :avg_connect_time, :decimal
      add :avg_tls_time, :decimal
      add :avg_first_byte_time, :decimal
      add :avg_to_finish, :decimal
      add :avg_request_time, :decimal
    end

    create unique_index(:uptime_check_summaries, [:service_id, :date])
  end
end
