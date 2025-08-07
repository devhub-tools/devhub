defmodule Devhub.Repo.Migrations.WorkflowStepDeferNameUnique do
  use Ecto.Migration

  def change do
    drop unique_index(:workflow_steps, [:workflow_id, :name])

    execute """
      ALTER TABLE "workflow_steps"
      ADD CONSTRAINT "workflow_steps_workflow_id_name_unique" UNIQUE (workflow_id, name) DEFERRABLE INITIALLY DEFERRED
    """
  end
end
