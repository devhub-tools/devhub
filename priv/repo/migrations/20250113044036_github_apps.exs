defmodule Devhub.Repo.Migrations.GithubApps do
  use Ecto.Migration

  def change do
    create table(:github_apps) do
      add :organization_id, references(:organizations)
      add :external_id, :integer
      add :slug, :text
      add :client_id, :text
      add :client_secret, :binary
      add :webhook_secret, :binary
      add :private_key, :binary

      timestamps()
    end

    create unique_index(:github_apps, [:organization_id])
  end
end
