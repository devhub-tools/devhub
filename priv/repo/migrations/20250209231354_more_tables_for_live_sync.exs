defmodule Devhub.Repo.Migrations.MoreTablesForLiveSync do
  use Ecto.Migration

  def up do
    LiveSync.Migration.down()

    LiveSync.Migration.up([
      "querydesk_databases",
      "querydesk_query_approvals",
      "querydesk_queries",
      "terraform_plans"
    ])
  end

  def down do
  end
end
