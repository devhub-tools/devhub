defmodule Devhub.Repo.Migrations.CreateAgentsTable do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :name, :string, null: false
      add :organization_id, references(:organizations), null: false

      timestamps()
    end
  end
end
