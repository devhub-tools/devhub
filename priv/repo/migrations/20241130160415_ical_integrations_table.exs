defmodule Devhub.Repo.Migrations.IcalIntegrationsTable do
  use Ecto.Migration

  def change do
    create table(:integrations_ical) do
      add :organization_id, references(:organizations)
      add :link, :text, null: false
      add :title, :string
      add :color, :string, null: false

      timestamps()
    end
  end
end
