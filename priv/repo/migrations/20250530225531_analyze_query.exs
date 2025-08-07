defmodule Devhub.Repo.Migrations.AnalyzeQuery do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      add :analyze, :boolean, default: false, null: false
      add :plan, :map, null: true
    end
  end
end
