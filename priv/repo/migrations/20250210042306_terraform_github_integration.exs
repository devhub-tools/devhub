defmodule Devhub.Repo.Migrations.TerraformGithubIntegration do
  use Ecto.Migration

  def change do
    alter table(:terraform_workspaces) do
      add :repository_id, references(:repositories)
      modify :github_repository, :text, null: true, from: :text
      modify :github_default_branch, :text, null: true, from: :text
    end

    alter table(:terraform_plans) do
      add :commit_sha, :text
    end
  end
end
