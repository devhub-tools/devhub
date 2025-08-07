defmodule Devhub.Repo.Migrations.LiveSync do
  use Ecto.Migration

  def up do
    LiveSync.Migration.up([
      "querydesk_databases",
      "querydesk_query_approvals",
      "querydesk_queries"
    ])
  end

  def down do
    LiveSync.Migration.down()
  end
end
