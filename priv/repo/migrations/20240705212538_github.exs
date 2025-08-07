defmodule Devhub.Repo.Migrations.Metrics do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :organization_id, references(:organizations), null: false

      add :name, :string, null: false
      add :owner, :string, null: false
      add :enabled, :boolean, default: false, null: false
      add :pushed_at, :utc_datetime, null: false
      add :archived, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:repositories, [:organization_id, :name, :owner])

    create table(:commits) do
      add :organization_id, references(:organizations), null: false
      add :repository_id, references(:repositories), null: false

      add :message, :text, null: false
      add :sha, :string, null: false
      add :authored_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:commits, [:repository_id, :sha])

    create table(:github_users) do
      add :organization_id, references(:organizations), null: false
      add :username, :text, null: false
    end

    create unique_index(:github_users, [:organization_id, :username])

    alter table(:organization_users) do
      add :github_user_id, references(:github_users)
    end

    create unique_index(:organization_users, [:github_user_id])

    create table(:commit_authors, primary_key: false) do
      add :commit_id, references(:commits), null: false, primary_key: true
      add :github_user_id, references(:github_users), null: false, primary_key: true
    end

    create table(:pull_requests) do
      add :organization_id, references(:organizations), null: false
      add :repository_id, references(:repositories), null: false

      add :number, :integer, null: false
      add :title, :string, null: false
      add :state, :text
      add :additions, :integer
      add :deletions, :integer
      add :changed_files, :integer
      add :author, :text
      add :first_commit_authored_at, :utc_datetime
      add :opened_at, :utc_datetime
      add :merged_at, :utc_datetime
      add :first_review_at, :utc_datetime
      add :comments_count, :integer

      timestamps()
    end

    create unique_index(:pull_requests, [:repository_id, :number])

    create table(:pull_request_reviews) do
      add :organization_id, references(:organizations), null: false
      add :pull_request_id, references(:pull_requests), null: false

      add :github_id, :text, null: false
      add :author, :text, null: false
      add :reviewed_at, :utc_datetime
    end

    create unique_index(:pull_request_reviews, [:pull_request_id, :github_id])
  end
end
