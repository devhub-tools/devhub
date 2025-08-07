defmodule Devhub.Repo.Migrations.Linear do
  use Ecto.Migration

  def change do
    create table(:linear_projects) do
      add :organization_id, references(:organizations), null: false
      add :external_id, :text, null: false

      add :name, :text, null: false
      add :archived_at, :utc_datetime
      add :canceled_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :created_at, :utc_datetime
      add :status, :text
    end

    create unique_index(:linear_projects, [:organization_id, :external_id])

    create table(:linear_teams) do
      add :organization_id, references(:organizations), null: false
      add :external_id, :text, null: false

      add :name, :text
      add :key, :text
    end

    create unique_index(:linear_teams, [:organization_id, :external_id])

    create table(:linear_users) do
      add :organization_id, references(:organizations), null: false
      add :external_id, :text, null: false
      add :name, :text
    end

    create unique_index(:linear_users, [:organization_id, :external_id])

    alter table(:organization_users) do
      add :linear_user_id, references(:linear_users)
    end

    create unique_index(:organization_users, [:linear_user_id])

    create table(:linear_issues) do
      add :organization_id, references(:organizations), null: false
      add :linear_user_id, references(:linear_users)
      add :external_id, :text, null: false

      add :archived_at, :utc_datetime
      add :canceled_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :created_at, :utc_datetime
      add :estimate, :integer
      add :identifier, :text
      add :started_at, :utc_datetime
      add :title, :text
      add :url, :text

      add :linear_team_id, references(:linear_teams)
    end

    create unique_index(:linear_issues, [:organization_id, :external_id])

    create table(:linear_labels) do
      add :organization_id, references(:organizations), null: false
      add :external_id, :text, null: false
      add :type, :text, default: "feature", null: false

      add :name, :text
      add :color, :text
    end

    create unique_index(:linear_labels, [:organization_id, :external_id])

    create table(:linear_issues_labels, primary_key: false) do
      add :issue_id, references(:linear_issues), primary_key: true, null: false
      add :label_id, references(:linear_labels), primary_key: true, null: false
    end
  end
end
