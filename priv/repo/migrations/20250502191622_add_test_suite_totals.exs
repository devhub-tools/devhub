defmodule Devhub.Repo.Migrations.AddTestSuiteTotals do
  use Ecto.Migration

  import Ecto.Query

  alias Devhub.Repo

  def up do
    alter table(:test_suite_runs) do
      add :execution_time_seconds, :decimal, null: true
      add :number_of_tests, :integer, null: true
      add :number_of_errors, :integer, null: true
      add :number_of_failures, :integer, null: true
      add :number_of_skipped, :integer, null: true
    end

    flush()

    backfill_totals()

    execute("ALTER TABLE test_suite_runs ALTER COLUMN execution_time_seconds SET NOT NULL;")
    execute("ALTER TABLE test_suite_runs ALTER COLUMN number_of_tests SET NOT NULL;")
    execute("ALTER TABLE test_suite_runs ALTER COLUMN number_of_errors SET NOT NULL;")
    execute("ALTER TABLE test_suite_runs ALTER COLUMN number_of_failures SET NOT NULL;")
    execute("ALTER TABLE test_suite_runs ALTER COLUMN number_of_skipped SET NOT NULL;")
  end

  def down do
    alter table(:test_suite_runs) do
      remove :execution_time_seconds
      remove :number_of_tests
      remove :number_of_errors
      remove :number_of_failures
      remove :number_of_skipped
    end
  end

  defp backfill_totals do
    query =
      from(tfr in "test_file_runs",
        group_by: tfr.test_suite_run_id,
        select: %{
          test_suite_run_id: tfr.test_suite_run_id,
          execution_time: sum(tfr.execution_time_seconds),
          number_of_tests: sum(tfr.number_of_tests),
          number_of_errors: sum(tfr.number_of_errors),
          number_of_failures: sum(tfr.number_of_failures),
          number_of_skipped: sum(tfr.number_of_skipped)
        }
      )

    Repo.all(query)
    |> Enum.map(fn %{test_suite_run_id: test_suite_run_id} = totals ->
      from(tsr in "test_suite_runs",
        where: tsr.id == ^test_suite_run_id,
        update: [
          set: [
            execution_time_seconds: ^totals.execution_time,
            number_of_tests: ^totals.number_of_tests,
            number_of_errors: ^totals.number_of_errors,
            number_of_failures: ^totals.number_of_failures,
            number_of_skipped: ^totals.number_of_skipped
          ]
        ]
      )
      |> Repo.update_all([])
    end)
  end
end
