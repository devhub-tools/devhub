defmodule Devhub.Repo.Migrations.ManagedRoles do
  use Ecto.Migration

  def change do
    alter table(:roles) do
      add :managed, :boolean, default: false
      modify :name, :citext, from: :string, null: false
    end
  end
end
