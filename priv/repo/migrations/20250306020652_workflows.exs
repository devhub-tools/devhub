defmodule Devhub.Repo.Migrations.Workflows do
  use Ecto.Migration

  def change do
    create table(:workflows) do
      add :organization_id, references(:organizations), null: false
      add :name, :text, null: false
      add :inputs, :map
      add :archived_at, :utc_datetime

      timestamps()
    end

    create unique_index(:workflows, [:organization_id, :name], where: "archived_at IS NULL")

    create table(:workflow_steps) do
      add :workflow_id, references(:workflows), null: false
      add :order, :integer, null: false
      add :action, :map, null: false
      add :secrets, :binary

      timestamps()
    end

    create index(:workflow_steps, [:workflow_id])

    create table(:workflow_runs) do
      add :organization_id, references(:organizations), null: false
      add :workflow_id, references(:workflows), null: false
      add :triggered_by_user_id, references(:users)
      add :status, :text, null: false
      add :input, :map
      add :steps, :map

      timestamps()
    end

    create index(:workflow_runs, [:organization_id])
    create index(:workflow_runs, [:workflow_id])

    alter table(:object_permissions) do
      add :workflow_id, references(:workflows, on_delete: :delete_all)
      add :workflow_step_id, references(:workflow_steps, on_delete: :delete_all)
    end

    create unique_index(:object_permissions, [:workflow_id, :organization_user_id],
             where: "workflow_id IS NOT NULL"
           )

    create unique_index(:object_permissions, [:workflow_step_id, :organization_user_id],
             where: "workflow_step_id IS NOT NULL"
           )
  end
end
