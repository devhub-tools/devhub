defmodule Devhub.Repo.Migrations.UserPreferences do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :preferences, :map
    end
  end
end
