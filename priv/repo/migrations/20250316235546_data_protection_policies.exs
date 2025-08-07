defmodule Devhub.Repo.Migrations.DataProtectionPolicies do
  use Ecto.Migration

  def change do
    create table(:data_protection_policies) do
      add :organization_id, references(:organizations), null: false
      add :database_id, references(:querydesk_databases), null: false
      add :name, :text, null: false
      add :description, :text

      timestamps()
    end

    create unique_index(:data_protection_policies, [:organization_id, :database_id, :name])

    create table(:data_protection_columns) do
      add :policy_id, references(:data_protection_policies, on_delete: :delete_all), null: false
      add :column_id, references(:querydesk_database_columns), null: false
      add :action, :text, null: false, default: "hide"
      add :custom_action_id, references(:querydesk_database_protection_actions)
    end

    create unique_index(:data_protection_columns, [:policy_id, :column_id])

    alter table(:object_permissions) do
      add :data_protection_policy_id, references(:data_protection_policies)
    end

    drop index(:querydesk_database_protection_actions, [:database_id])
    rename table(:querydesk_database_protection_actions), to: table(:data_protection_actions)
    create unique_index(:data_protection_actions, [:database_id, :table, :name])
  end
end
