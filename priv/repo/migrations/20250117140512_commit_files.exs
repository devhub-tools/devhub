defmodule Devhub.Repo.Migrations.CommitFiles do
  use Ecto.Migration

  def change do
    create table(:commit_files) do
      add :organization_id, references(:organizations, on_delete: :delete_all), null: false
      add :commit_id, references(:commits, on_delete: :delete_all), null: false
      add :filename, :text, null: false
      add :extension, :text, null: false
      add :additions, :integer, null: false
      add :deletions, :integer, null: false
      add :patch, :text
      add :status, :text, null: false

      timestamps()
    end

    create unique_index(:commit_files, [:commit_id, :filename])
  end
end
