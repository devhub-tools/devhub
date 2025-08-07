defmodule Devhub.Repo.Migrations.BypassDataProtection do
  use Ecto.Migration

  def change do
    alter table(:querydesk_queries) do
      add :bypass_data_protection, :boolean, default: false, null: false
    end
  end
end
