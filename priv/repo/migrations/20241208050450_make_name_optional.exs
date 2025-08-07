defmodule Devhub.Repo.Migrations.MakeNameOptional do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :name, :string, null: true
    end
  end
end
