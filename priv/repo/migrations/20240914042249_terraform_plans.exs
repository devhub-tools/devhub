defmodule Devhub.TerraDesk.Repo.Migrations.TerraformPlans do
  use Ecto.Migration

  def change do
    create table(:terraform_plans) do
      add :workspace_id, references(:terraform_workspaces), null: false
      add :user_id, references(:users)
      add :github_branch, :string, null: false
      add :status, :text, null: false, default: "pending"
      add :output, :binary
      add :log, :binary

      timestamps()
    end

    create unique_index(:terraform_plans, [:workspace_id, :status], where: "status = 'pending'")
  end
end
