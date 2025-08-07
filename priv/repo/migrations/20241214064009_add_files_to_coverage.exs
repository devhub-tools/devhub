defmodule Devhub.Repo.Migrations.AddFilesToCoverage do
  use Ecto.Migration

  def change do
    alter table(:coverage) do
      add :files, :map
    end
  end
end
