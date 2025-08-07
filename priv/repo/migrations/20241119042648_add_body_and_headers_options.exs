defmodule Devhub.Repo.Migrations.AddBodyAndHeadersOptions do
  use Ecto.Migration

  def change do
    alter table(:uptime_services) do
      add :request_body, :string
      add :request_headers, :map
    end

    alter table(:uptime_checks) do
      add :response_headers, :map
    end
  end
end
