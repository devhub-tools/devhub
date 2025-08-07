defmodule Devhub.Repo.Migrations.UserProxyPassword do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :proxy_password, :map
    end

    alter table(:organizations) do
      add :proxy_password_expiration_seconds, :integer, default: 3600, null: false
    end
  end
end
