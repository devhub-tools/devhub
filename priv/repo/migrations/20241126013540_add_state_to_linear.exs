defmodule Devhub.Repo.Migrations.AddStateToLinear do
  use Ecto.Migration

  def change do
    alter table(:linear_issues) do
      add :state, :map
    end
  end
end
