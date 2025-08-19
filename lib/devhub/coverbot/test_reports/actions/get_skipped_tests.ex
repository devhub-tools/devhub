defmodule Devhub.Coverbot.TestReports.Actions.GetSkippedTests do
  @moduledoc false

  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.TestReports.Schemas.TestRun
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Repo

  @callback get_skipped_tests(String.t()) :: [TestRun.t()]
  def get_skipped_tests(test_suite_id) do
    latest_run_id_query =
      from tsr in TestSuiteRun,
        where: tsr.test_suite_id == ^test_suite_id,
        order_by: [desc: tsr.inserted_at],
        limit: 1,
        select: tsr.id

    skipped_tests_query =
      from tr in TestRun,
        where: tr.test_suite_run_id == subquery(latest_run_id_query) and tr.status == :skipped

    skipped_tests = Repo.all(skipped_tests_query)

    Enum.map(skipped_tests, fn test_run ->
      first_skipped_query =
        from tr in TestRun,
          join: tsr in TestSuiteRun,
          on: tr.test_suite_run_id == tsr.id,
          where:
            tsr.test_suite_id == ^test_suite_id and
              tr.status == :skipped and
              tr.test_name == ^test_run.test_name and
              tr.class_name == ^test_run.class_name,
          order_by: tr.inserted_at,
          limit: 1,
          preload: [test_suite_run: :commit]

      Repo.one(first_skipped_query)
    end)
  end
end
