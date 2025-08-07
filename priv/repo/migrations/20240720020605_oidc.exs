defmodule Devhub.Repo.Migrations.Oidc do
  use Ecto.Migration

  def change do
    create table(:oidc_configs) do
      add :organization_id, references(:organizations)
      add :discovery_document_uri, :text
      add :client_id, :text
      add :client_secret, :binary

      timestamps()
    end

    create unique_index(:oidc_configs, [:organization_id])
  end
end
