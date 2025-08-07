defmodule Devhub.Repo.Migrations.RemoveTestFileRun do
  use Ecto.Migration

  import Ecto.Query
  alias Devhub.Repo

  def up do
    alter table(:test_suite_runs) do
      add :seed, :text
    end

    alter table(:test_runs) do
      add :test_suite_run_id, references(:test_suite_runs)
    end

    create index(:test_runs, [:test_suite_run_id])

    flush()

    test_file_run_mappings =
      from(tfr in "test_file_runs",
        select: %{
          test_file_run_id: tfr.id,
          test_suite_run_id: tfr.test_suite_run_id,
          seed: tfr.seed
        }
      )
      |> Repo.all()

    # backfill test_suite_run_id
    test_file_run_mappings
    |> Enum.map(fn %{test_file_run_id: test_file_run_id, test_suite_run_id: test_suite_run_id} ->
      from(tr in "test_runs",
        where: tr.test_file_run_id == ^test_file_run_id,
        update: [set: [test_suite_run_id: ^test_suite_run_id]]
      )
      |> Repo.update_all([])
    end)

    # backfill seed
    test_file_run_mappings
    |> Enum.uniq_by(fn %{test_suite_run_id: test_suite_run_id} -> test_suite_run_id end)
    |> Enum.map(fn %{test_suite_run_id: test_suite_run_id, seed: seed} ->
      from(tsr in "test_suite_runs",
        where: tsr.id == ^test_suite_run_id,
        update: [set: [seed: ^seed]]
      )
      |> Repo.update_all([])
    end)

    alter table(:test_runs) do
      modify :test_suite_run_id, :text, null: false
    end

    drop index(:test_runs, [:test_file_run_id])

    alter table(:test_runs) do
      remove :test_file_run_id
    end

    drop table(:test_file_runs)
  end

  def down do
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

    alter table(:test_runs) do
      add :test_file_run_id, references(:test_file_runs)
    end

    create index(:test_runs, [:test_file_run_id])

    drop index(:test_runs, [:test_suite_run_id])

    alter table(:test_runs) do
      remove :test_suite_run_id
    end

    alter table(:test_suite_runs) do
      remove :seed
    end
  end
end
