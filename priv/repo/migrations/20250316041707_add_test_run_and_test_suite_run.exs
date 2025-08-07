defmodule Devhub.Repo.Migrations.AddTestRunAndTestSuiteRun do
  use Ecto.Migration

  def change do
    create table(:test_suite_runs) do
      add :commit_id, references(:commits), null: false
      add :organization_id, references(:organizations), null: false

      timestamps()
    end

    create index(:test_suite_runs, [:organization_id, :commit_id])

    create table(:test_file_runs) do
      add :test_suite_run_id, references(:test_suite_runs), null: false
      add :file_name, :text, null: false
      add :number_of_tests, :integer, null: false
      add :number_of_errors, :integer, null: false
      add :number_of_failures, :integer, null: false
      add :number_of_skipped, :integer, null: false
      add :execution_time_seconds, :decimal, null: false
      add :executed_at, :utc_datetime_usec, null: false
      add :seed, :text

      timestamps()
    end

    create index(:test_file_runs, [:test_suite_run_id])

    create table(:test_runs) do
      add :test_file_run_id, references(:test_file_runs), null: false
      add :class_name, :text, null: false
      add :file_name, :text, null: false
      add :test_name, :text, null: false
      add :execution_time_seconds, :decimal, null: false
      add :status, :text
      add :info, :map

      timestamps()
    end

    create index(:test_runs, [:test_file_run_id])
  end
end
