defmodule Devhub.Repo.Migrations.CleanupOldDataProtection do
  use Ecto.Migration

  def change do
    alter table(:querydesk_database_columns) do
      remove :data_protection_action
      remove :custom_protection_action_id
    end
  end
end
