defmodule Devhub.Repo.Migrations.AddOrganizationIdToTf do
  use Ecto.Migration

  def change do
    alter table(:terraform_workspaces) do
      add :organization_id, references(:organizations), null: false
    end

    alter table(:terraform_plans) do
      add :organization_id, references(:organizations), null: false
    end

    alter table(:google_workload_identities) do
      add :organization_id, references(:organizations), null: false
    end
  end
end
