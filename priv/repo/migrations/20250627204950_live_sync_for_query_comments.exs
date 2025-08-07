defmodule Devhub.Repo.Migrations.LiveSyncForQueryComments do
  use Ecto.Migration

  def up do
    LiveSync.Migration.down()

    LiveSync.Migration.up([
      "querydesk_databases",
      "querydesk_queries",
      "querydesk_query_approvals",
      "querydesk_query_comments",
      "terraform_plans",
      "terraform_workspaces",
      "uptime_checks",
      "workflow_runs"
    ])
  end

  def down do
  end
end
