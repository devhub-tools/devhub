defmodule Devhub.Repo.Migrations.PlanApprovals do
  use Ecto.Migration

  def change do
    alter table(:terraform_plans) do
      add :approvals, :map
    end
  end
end
