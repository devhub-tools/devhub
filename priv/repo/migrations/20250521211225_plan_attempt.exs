defmodule Devhub.Repo.Migrations.PlanAttempt do
  use Ecto.Migration

  def change do
    alter table(:terraform_plans) do
      add :attempt, :integer, default: 1, null: false
    end
  end
end
