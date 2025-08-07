defmodule Devhub.Repo.Migrations.QueryOptions do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      add :timeout, :integer, default: 5, null: false
      add :run_on_approval, :boolean, default: false, null: false
    end
  end
end
