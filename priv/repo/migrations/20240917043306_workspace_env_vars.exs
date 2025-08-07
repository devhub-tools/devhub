defmodule Devhub.TerraDesk.Repo.Migrations.WorkspaceEnvVars do
  use Ecto.Migration

  def change do
    create table(:terraform_env_vars) do
      add :workspace_id, references(:terraform_workspaces), null: false
      add :name, :text, null: false
      add :value, :text, null: false

      timestamps()
    end
  end
end
