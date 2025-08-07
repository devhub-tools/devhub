defmodule Devhub.Repo.Migrations.AddTestSuitesTable do
  use Ecto.Migration

  import Ecto.Query

  alias Devhub.Repo

  # This migration assumes that right now there is only one test_suite for organization_id

  def up do
    create table(:test_suites) do
      add :organization_id, references(:organizations), null: false
      add :name, :text, null: false
      add :repository_id, references(:repositories), null: false

      timestamps()
    end

    create index(:test_suites, [:organization_id, :repository_id])
    create unique_index(:test_suites, [:name, :organization_id, :repository_id])

    alter table(:test_suite_runs) do
      add :test_suite_id, references(:test_suites), null: true
    end

    flush()

    create_test_suites()

    alter table(:test_suite_runs) do
      remove :organization_id
      modify :test_suite_id, :text, null: false
    end
  end

  def down() do
    alter table(:test_suite_runs) do
      add :organization_id, references(:organizations), null: true
      remove :test_suite_id
    end

    flush()

    backfill_test_suite_run_org_id()

    drop index(:test_suites, [:name, :organization_id, :repository_id])
    drop index(:test_suites, [:organization_id, :repository_id])

    drop table(:test_suites)

    alter table(:test_suite_runs) do
      modify :organization_id, :text, null: false
    end
  end

  defp create_test_suites() do
    id = UXID.generate!(prefix: "test_suite")

    query =
      from(tsr in "test_suite_runs",
        left_join: c in "commits",
        on: tsr.commit_id == c.id,
        left_join: r in "repositories",
        on: c.repository_id == r.id,
        distinct: true,
        select: %{
          id: ^id,
          name: r.name,
          organization_id: tsr.organization_id,
          repository_id: c.repository_id,
          inserted_at: fragment("now()::timestamp"),
          updated_at: fragment("now()::timestamp")
        }
      )

    Repo.insert_all("test_suites", query)

    from(tsr in "test_suite_runs",
      update: [
        set: [
          test_suite_id: ^id
        ]
      ]
    )
    |> Repo.update_all([])
  end

  defp backfill_test_suite_run_org_id() do
    organization_id =
      from(ts in "test_suites",
        distinct: true,
        select: ts.organization_id
      )
      |> Repo.one()

    from(tsr in "test_suite_runs",
      update: [
        set: [
          organization_id: ^organization_id
        ]
      ]
    )
    |> Repo.update_all([])
  end
end
