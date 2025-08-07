defmodule Devhub.TerraDesk.Repo.Migrations.GoogleWorkloadIdentity do
  use Ecto.Migration

  def change do
    create table(:google_workload_identities) do
      add :workspace_id, references(:terraform_workspaces), null: false
      add :service_account_email, :string
      add :provider, :string
      add :enabled, :boolean, default: false

      timestamps()
    end

    create unique_index(:google_workload_identities, [:workspace_id])
  end
end
