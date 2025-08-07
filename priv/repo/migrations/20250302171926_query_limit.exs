defmodule Devhub.Repo.Migrations.QueryLimit do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      add :limit, :integer, default: 100, null: false
    end
  end
end
