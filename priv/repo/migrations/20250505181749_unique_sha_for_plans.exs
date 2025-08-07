defmodule Devhub.Repo.Migrations.UniqueShaForPlans do
  use Ecto.Migration

  def change do
    create unique_index(:terraform_plans, [:workspace_id, :commit_sha])
  end
end
