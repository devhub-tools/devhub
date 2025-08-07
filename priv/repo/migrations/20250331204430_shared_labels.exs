defmodule Devhub.Repo.Migrations.SharedLabels do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :organization_id, references(:organizations), null: false
      add :name, :citext, null: false
      add :color, :text, null: false

      timestamps()
    end

    create unique_index(:labels, [:organization_id, :name])

    create table(:labeled_objects) do
      add :organization_id, references(:organizations), null: false
      add :label_id, references(:labels, on_delete: :delete_all), null: false

      add :saved_query_id, references(:querydesk_saved_queries, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:labeled_objects, [:label_id, :saved_query_id],
             where: "saved_query_id IS NOT NULL"
           )
  end
end
