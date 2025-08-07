defmodule Devhub.Repo.Migrations.DatabaseUniqueName do
  use Ecto.Migration

  def change do
    create unique_index(:querydesk_databases, [:organization_id, :name, :group],
             where: "archived_at IS NULL",
             nulls_distinct: false
           )
  end
end
