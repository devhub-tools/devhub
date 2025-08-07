defmodule Devhub.Repo.Migrations.CommitDefaultBranch do
  use Ecto.Migration

  def change do
    alter table(:commits) do
      add :additions, :integer
      add :deletions, :integer
      add :on_default_branch, :boolean, default: false, null: false
    end
  end
end
