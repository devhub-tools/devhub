defmodule Devhub.Coverbot.TestReports.Actions.GetFlakyTests do
  @moduledoc false

  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.TestReports.Schemas.TestRun
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Repo

  @callback get_flaky_tests(String.t(), integer()) :: [
              %{
                test_name: String.t(),
                class_name: String.t(),
                failure_count: non_neg_integer(),
                first_failure_at: DateTime.t(),
                commit_sha: String.t(),
                info: map()
              }
            ]
  def get_flaky_tests(test_suite_id, past_n_runs) do
    recent_runs_query =
      from tsr in TestSuiteRun,
        where: tsr.test_suite_id == ^test_suite_id,
        order_by: [desc: tsr.inserted_at],
        limit: ^past_n_runs,
        select: tsr.id

    first_failure_subquery =
      from tr3 in TestRun,
        join: tsr3 in TestSuiteRun,
        on: tr3.test_suite_run_id == tsr3.id,
        join: c in Commit,
        on: tsr3.commit_id == c.id,
        where: tsr3.test_suite_id == ^test_suite_id,
        where: tr3.status == ^:failed,
        group_by: [tr3.test_name, tr3.class_name, c.sha],
        select: %{
          class_name: tr3.class_name,
          test_name: tr3.test_name,
          first_failure_at: min(tr3.inserted_at),
          commit_sha: c.sha
        }

    query =
      from tr in TestRun,
        join: tsr in TestSuiteRun,
        on: tr.test_suite_run_id == tsr.id,
        join: ff in subquery(first_failure_subquery),
        on: ff.test_name == tr.test_name and ff.class_name == tr.class_name,
        where: tsr.test_suite_id == ^test_suite_id,
        where: tr.status == ^:failed,
        where: tsr.id in subquery(recent_runs_query),
        group_by: [tr.test_name, tr.class_name, ff.first_failure_at, ff.commit_sha],
        select: %{
          test_name: tr.test_name,
          class_name: tr.class_name,
          failure_count: count(tr.id),
          first_failure_at: ff.first_failure_at,
          commit_sha: ff.commit_sha,
          # use aggregate function to get most recent info since tr.info is not in GROUP BY
          info: fragment("(array_agg(? ORDER BY ? DESC))[1]", tr.info, tr.inserted_at)
        }

    result = Repo.all(query)

    Enum.sort_by(result, &{&1.failure_count, &1.test_name}, :desc)
  end
end
