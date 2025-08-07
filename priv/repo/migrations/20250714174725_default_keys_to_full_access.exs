defmodule Devhub.Repo.Migrations.DefaultKeysToFullAccess do
  use Ecto.Migration

  def change do
    execute "UPDATE api_keys SET permissions = '{full_access}'"
  end
end
