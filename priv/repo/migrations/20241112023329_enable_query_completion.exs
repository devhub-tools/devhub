defmodule Devhub.Repo.Migrations.EnableQueryCompletion do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :enable_query_completion, :boolean, default: false
    end
  end
end
