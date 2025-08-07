defmodule Devhub.Repo.Migrations.WorkflowStepCondition do
  use Ecto.Migration

  def change do
    alter table(:workflow_steps) do
      add :condition, :string
    end
  end
end
