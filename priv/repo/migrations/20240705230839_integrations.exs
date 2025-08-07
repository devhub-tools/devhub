defmodule Devhub.Repo.Migrations.Integrations do
  use Ecto.Migration

  def change do
    create table(:integrations) do
      add :organization_id, references(:organizations), null: false
      add :provider, :text, null: false
      add :external_id, :text
      add :access_token, :binary

      timestamps()
    end

    create unique_index(:integrations, [:organization_id, :provider])
  end
end
