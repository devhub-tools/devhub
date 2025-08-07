defmodule Devhub.Repo.Migrations.DropUniquePathIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:terraform_workspaces, [:github_repository, :path])
  end
end
