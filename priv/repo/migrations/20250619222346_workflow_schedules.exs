defmodule Devhub.Repo.Migrations.WorkflowSchedules do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      add :cron_schedule, :string, null: true
    end
  end
end
