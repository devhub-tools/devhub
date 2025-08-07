defmodule Devhub.Repo.Migrations.RepoDefaultBranch do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :default_branch, :string, default: "main", null: false
    end
  end
end
