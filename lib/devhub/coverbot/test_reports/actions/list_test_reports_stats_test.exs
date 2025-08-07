defmodule Devhub.Coverbot.TestReports.Actions.ListTestReportStatsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Coverbot
  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun

  test "list_test_report_stats/1" do
    %{id: organization_id} = organization = insert(:organization)
    repository = insert(:repository, organization_id: organization_id)

    %{id: test_suite_id_1} =
      test_suite_1 = insert(:test_suite, name: "test_suite_1", organization: organization, repository: repository)

    %{id: test_suite_id_2} =
      test_suite_2 = insert(:test_suite, name: "test_suite_2", organization: organization, repository: repository)

    %{id: _test_suite_run_1} =
      insert(:test_suite_run, organization: organization, repository: repository, test_suite: test_suite_1)

    # last test suite run for test_suite_1
    %{id: test_suite_run_2} =
      insert(:test_suite_run, organization: organization, repository: repository, test_suite: test_suite_1)

    %{id: _test_suite_run_3} =
      insert(:test_suite_run, organization: organization, repository: repository, test_suite: test_suite_2)

    # last test suite run for test_suite_2
    %{id: test_suite_run_4} =
      insert(:test_suite_run, organization: organization, repository: repository, test_suite: test_suite_2)

    assert [
             # showing test_suite_2 first, because test_suite_run_4 ran last
             %{
               test_suite: %TestSuite{id: ^test_suite_id_2, repository: ^repository},
               last_test_suite_run: %TestSuiteRun{id: ^test_suite_run_4}
             },
             %{
               test_suite: %TestSuite{id: ^test_suite_id_1, repository: ^repository},
               last_test_suite_run: %TestSuiteRun{id: ^test_suite_run_2}
             }
           ] = Coverbot.list_test_report_stats(organization)
  end
end
