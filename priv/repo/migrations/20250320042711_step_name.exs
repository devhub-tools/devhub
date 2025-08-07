defmodule Devhub.Repo.Migrations.StepName do
  use Ecto.Migration

  def change do
    alter table(:workflow_steps) do
      add :name, :string
    end

    create unique_index(:workflow_steps, [:workflow_id, :name])
  end
end
