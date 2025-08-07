defmodule Devhub.Repo.Migrations.TerraformSchedule do
  use Ecto.Migration

  def change do
    create table(:terraform_schedules) do
      add :organization_id, references(:organizations), null: false
      add :name, :string, null: false
      add :cron_expression, :string, null: false
      add :slack_channel, :string
      add :enabled, :boolean, default: true
    end

    alter table(:terraform_plans) do
      add :schedule_id, references(:terraform_schedules)
    end

    create index(:terraform_plans, [:schedule_id])

    create table(:terraform_workspace_schedules, primary_key: false) do
      add :workspace_id, references(:terraform_workspaces, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :schedule_id, references(:terraform_schedules, on_delete: :delete_all),
        null: false,
        primary_key: true
    end
  end
end
