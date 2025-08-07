defmodule Devhub.Coverbot do
  @moduledoc false

  @behaviour Devhub.Coverbot.Actions.CoverageData
  @behaviour Devhub.Coverbot.Actions.CoveragePercentage
  @behaviour Devhub.Coverbot.Actions.CreateCoverage
  @behaviour Devhub.Coverbot.Actions.GetCoverage
  @behaviour Devhub.Coverbot.Actions.GetLatestCoverage
  @behaviour Devhub.Coverbot.Actions.LineCovered
  @behaviour Devhub.Coverbot.Actions.ListCoverage
  @behaviour Devhub.Coverbot.Actions.ListRepositoryRefs
  @behaviour Devhub.Coverbot.Actions.ParseFileCoverage
  @behaviour Devhub.Coverbot.Actions.UpsertCoverage
  @behaviour Devhub.Coverbot.TestReports.Actions.GetTestSuite
  @behaviour Devhub.Coverbot.TestReports.Actions.GetTestSuiteRun
  @behaviour Devhub.Coverbot.TestReports.Actions.ListTestReportStats
  @behaviour Devhub.Coverbot.TestReports.Actions.ParseJUnitFile
  @behaviour Devhub.Coverbot.TestReports.Actions.UpsertTestSuite

  alias Devhub.Coverbot.Actions
  alias Devhub.Coverbot.TestReports.Actions, as: TestReportsActions

  @impl Actions.CoverageData
  defdelegate coverage_data(repository_id), to: Actions.CoverageData

  @impl Actions.CoveragePercentage
  defdelegate coverage_percentage(repository, branch), to: Actions.CoveragePercentage

  @impl Actions.CreateCoverage
  defdelegate create_coverage(coverage_info), to: Actions.CreateCoverage

  @impl Actions.GetCoverage
  defdelegate get_coverage(by), to: Actions.GetCoverage

  @impl Actions.GetLatestCoverage
  defdelegate get_latest_coverage(repository, default_branch), to: Actions.GetLatestCoverage

  @impl Actions.ListCoverage
  defdelegate list_coverage(organization), to: Actions.ListCoverage

  @impl Actions.ListRepositoryRefs
  defdelegate list_repository_refs(by), to: Actions.ListRepositoryRefs

  @impl Actions.ParseFileCoverage
  defdelegate parse_file_coverage(coverage), to: Actions.ParseFileCoverage

  @impl Actions.LineCovered
  defdelegate line_covered?(coverage, line_number), to: Actions.LineCovered

  @impl Actions.UpsertCoverage
  defdelegate upsert_coverage(coverage_info), to: Actions.UpsertCoverage

  ### Test Reports
  @impl TestReportsActions.GetTestSuite
  defdelegate get_test_suite(test_suite_id), to: TestReportsActions.GetTestSuite

  @impl TestReportsActions.GetTestSuiteRun
  defdelegate get_test_suite_run(by), to: TestReportsActions.GetTestSuiteRun

  @impl TestReportsActions.ListTestReportStats
  defdelegate list_test_report_stats(organization), to: TestReportsActions.ListTestReportStats

  @impl TestReportsActions.ParseJUnitFile
  defdelegate parse_junit_file(test_suite, report_file, commit), to: TestReportsActions.ParseJUnitFile

  @impl TestReportsActions.UpsertTestSuite
  defdelegate upsert_test_suite(params), to: TestReportsActions.UpsertTestSuite
end
