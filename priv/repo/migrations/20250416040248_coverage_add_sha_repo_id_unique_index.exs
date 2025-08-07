defmodule Devhub.Repo.Migrations.CoverageAddShaRepoIdUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:coverage, [:sha, :repository_id])
  end
end
