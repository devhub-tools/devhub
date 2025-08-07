defmodule Devhub.Repo.Migrations.ApiIdUnique do
  use Ecto.Migration

  def change do
    create unique_index(:querydesk_databases, [:organization_id, :api_id],
             where: "archived_at IS NULL"
           )
  end
end
