defmodule Devhub.Repo.Migrations.LiveSyncForWorkflows do
  use Ecto.Migration

  def up do
    LiveSync.Migration.down()

    LiveSync.Migration.up([
      "querydesk_databases",
      "querydesk_queries",
      "querydesk_query_approvals",
      "terraform_plans",
      "terraform_workspaces",
      "uptime_checks",
      "workflow_runs"
    ])
  end

  def down do
  end
end
