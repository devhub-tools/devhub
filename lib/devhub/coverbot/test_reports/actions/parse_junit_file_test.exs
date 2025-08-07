defmodule Devhub.Coverbot.TestReports.Actions.ParseJUnitFileTest do
  use Devhub.DataCase, async: true

  import ExUnit.CaptureLog

  alias Devhub.Coverbot
  alias Devhub.Coverbot.TestReports.Schemas.TestRun
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun

  test "successful parsing" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: repo_id} = repository = insert(:repository, organization_id: organization_id)

    test_suite =
      insert(:test_suite,
        name: "devhub_elixir",
        organization: organization,
        repository: repository
      )

    %{id: commit_id} =
      commit = insert(:commit, repository_id: repo_id, organization_id: organization_id)

    report_file = File.read!("test/support/junit/devhub-report_file_test.xml")

    assert {:ok, test_suite_run} =
             Coverbot.parse_junit_file(test_suite, report_file, commit)

    assert %TestSuiteRun{
             commit_id: ^commit_id,
             test_runs: test_runs,
             number_of_tests: 12,
             number_of_errors: 1,
             number_of_failures: 1,
             execution_time_seconds: test_suite_execution_time,
             number_of_skipped: 1,
             seed: "408788"
           } = test_suite_run

    assert Decimal.equal?(test_suite_execution_time, "0.5278")

    assert [
             %TestRun{
               class_name: "Elixir.Devhub.Agents.ClientTest",
               file_name: "lib/devhub/agents/client_test.exs",
               test_name: "test success",
               status: :errored,
               info: %TestRun.Info{
                 message: "Invalid module Elixir.ExUnit.TestModule",
                 stacktrace:
                   ~s(%ExUnit.TestModule{file: "/Users/gaia/devhub/devhub/lib/devhub/agents/client_test.exs", name: Devhub.Agents.ClientTest, setup_all?: true, state: {:failed, [{{:EXIT, #PID<0.1033.0>}, :killed, []}]}, parameters: %{}, tags: %{}, tests: [%ExUnit.Test{name: :"test success", case: Devhub.Agents.ClientTest, module: Devhub.Agents.ClientTest, state: nil, time: 0, tags: %{line: 14, registered: %{}, file: "/Users/gaia/devhub/devhub/lib/devhub/agents/client_test.exs", describe: nil, describe_line: nil, test_type: :test}, logs: "", parameters: %{}}]})
               }
             },
             %TestRun{
               class_name: "Elixir.Devhub.ApiKeysTest",
               file_name: "lib/devhub/api_keys_test.exs",
               test_name: "test api_key flow",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test mysql success",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test mysql bad creds",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test postgres bad host",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test postgres bad creds",
               status: :failed,
               info: %TestRun.Info{
                 message: "match (=) failed",
                 stacktrace:
                   ~s|  3) test postgres bad creds (Devhub.QueryDesk.Actions.TestConnectionTest)\n     lib/devhub/querydesk/actions/test_connection_test.exs:21\n     match (=) failed\n     code:  assert {:error, "password authentication failed for user \\"postgres\\""} =\n              QueryDesk.test_connection(database, credential_id)\n     left:  {:error, "password authentication failed for user \\"postgres\\""}\n     right: :ok\n     stacktrace:\n       lib/devhub/querydesk/actions/test_connection_test.exs:32: (test)\n|
               }
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test mysql bad host",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.QueryDesk.Actions.TestConnectionTest",
               file_name: "lib/devhub/querydesk/actions/test_connection_test.exs",
               test_name: "test postgres success",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.CalendarTest",
               file_name: "lib/devhub/calendar_test.exs",
               test_name: "test get_events/3",
               status: :skipped,
               info: %TestRun.Info{
                 message: "due to skip filter",
                 stacktrace: nil
               }
             },
             %TestRun{
               class_name: "Elixir.Devhub.CalendarTest",
               file_name: "lib/devhub/calendar_test.exs",
               test_name: "test count_business_days/2",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.CalendarTest",
               file_name: "lib/devhub/calendar_test.exs",
               test_name: "test sync/1",
               status: :passed,
               info: nil
             },
             %TestRun{
               class_name: "Elixir.Devhub.CalendarTest",
               file_name: "lib/devhub/calendar_test.exs",
               test_name: "test create_event/1",
               status: :passed,
               info: nil
             }
           ] = test_runs
  end

  test "unsuccesful parsing" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: repo_id} = repository = insert(:repository, organization_id: organization_id)

    test_suite =
      insert(:test_suite,
        name: "devhub_elixir",
        organization: organization,
        repository: repository
      )

    commit = insert(:commit, repository_id: repo_id, organization_id: organization_id)

    report_file = """
    <?xmlsd>
      <testsuites>>
      </ciao>
    """

    log =
      capture_log(fn ->
        assert {:error, :error_parsing_junit_file} =
                 Coverbot.parse_junit_file(test_suite, report_file, commit)
      end)

    assert log =~ "[error] Error parsing junit file: {:ok, [{:pi, "
  end
end
