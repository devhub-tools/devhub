defmodule Devhub.Repo.Migrations.WorkspaceK8sSettings do
  use Ecto.Migration

  def change do
    alter table(:terraform_workspaces) do
      add :docker_image, :string, default: "hashicorp/terraform:1.10", null: false
      add :cpu_requests, :string, default: "100m", null: false
      add :memory_requests, :string, default: "512M", null: false
    end
  end
end
