defmodule Devhub.Repo.Migrations.IntegrationSettings do
  use Ecto.Migration

  def change do
    alter table(:integrations) do
      add :settings, :map
    end
  end
end
