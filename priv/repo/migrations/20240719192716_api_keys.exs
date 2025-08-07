defmodule Devhub.Repo.Migrations.ApiKeys do
  use Ecto.Migration

  def change() do
    create table(:api_keys) do
      add :organization_id, references(:organizations), null: false
      add :name, :string, null: false
      add :selector, :binary, null: false
      add :verify_hash, :binary, null: false
      add :expires_at, :utc_datetime, null: true
      add :permissions, {:array, :string}, default: [], null: false

      timestamps()
    end

    create unique_index(:api_keys, [:organization_id, :selector])
  end
end
