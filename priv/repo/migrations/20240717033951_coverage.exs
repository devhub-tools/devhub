defmodule Devhub.Repo.Migrations.Coverage do
  use Ecto.Migration

  def change do
    create table(:coverage) do
      add :organization_id, references(:organizations), null: false
      add :repository_id, references(:repositories), null: false
      add :is_for_default_branch, :boolean, null: false, default: false
      add :sha, :text, null: false
      add :ref, :text, null: false
      add :covered, :bigint, null: false
      add :relevant, :bigint, null: false
      add :percentage, :decimal, null: false

      timestamps()
    end

    create index(:coverage, [:organization_id, :repository_id, :ref])
  end
end
