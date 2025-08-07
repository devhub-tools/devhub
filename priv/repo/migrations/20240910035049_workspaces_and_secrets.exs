defmodule Devhub.TerraDesk.Repo.Migrations.WorkspacesAndSecrets do
  use Ecto.Migration

  def change() do
    create table(:terraform_workspaces) do
      add :name, :text, null: false
      add :github_repository, :text, null: false
      add :github_default_branch, :text, null: false
      add :path, :text
      add :init_args, :text
      add :required_approvals, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:terraform_workspaces, [:github_repository, :path])

    create table(:terraform_secrets) do
      add :workspace_id, references(:terraform_workspaces), null: false
      add :name, :text, null: false
      add :value, :binary, null: false

      timestamps()
    end
  end
end
