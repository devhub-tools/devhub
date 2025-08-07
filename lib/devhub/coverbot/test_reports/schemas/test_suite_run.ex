defmodule Devhub.Coverbot.TestReports.Schemas.TestSuiteRun do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Coverbot.TestReports.Schemas.TestRun
  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Integrations.GitHub.Commit

  @type t :: %__MODULE__{
          test_runs: [TestRun.t()],
          commit: Commit.t(),
          number_of_tests: integer(),
          number_of_errors: integer(),
          number_of_failures: integer(),
          number_of_skipped: integer(),
          execution_time_seconds: Decimal.t(),
          test_suite: TestSuite.t(),
          seed: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "test_suite_run"}
  schema "test_suite_runs" do
    field :number_of_tests, :integer
    field :number_of_errors, :integer
    field :number_of_failures, :integer
    field :number_of_skipped, :integer
    field :execution_time_seconds, :decimal
    field :seed, :string

    has_many :test_runs, TestRun

    belongs_to :test_suite, TestSuite
    belongs_to :commit, Commit

    timestamps()
  end

  def changeset(test_suite_run \\ %__MODULE__{}, params) do
    test_suite_run
    |> cast(params, [
      :test_suite_id,
      :number_of_tests,
      :number_of_errors,
      :number_of_failures,
      :number_of_skipped,
      :execution_time_seconds,
      :seed
    ])
    |> validate_required([
      :test_suite_id,
      :number_of_tests,
      :number_of_errors,
      :number_of_failures,
      :number_of_skipped,
      :execution_time_seconds,
      :seed
    ])
    |> foreign_key_constraint(:test_suite)
    |> put_assoc(:commit, params.commit)
    |> cast_assoc(:test_runs, with: &TestRun.changeset/2)
  end
end
