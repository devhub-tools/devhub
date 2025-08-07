defmodule Devhub.Repo.Migrations.PendingUsers do
  use Ecto.Migration

  def change do
    alter table(:organization_users) do
      add :pending, :boolean, default: false
    end
  end
end
