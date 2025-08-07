defmodule Devhub.Coverbot.TestReports.Actions.ParseJUnitFile do
  @moduledoc """
  parses a JUnit test file.

  https://github.com/victorolinasc/junit-formatter
  """

  @behaviour __MODULE__

  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Repo

  require Logger

  @callback parse_junit_file(TestSuite.t(), String.t(), Commit.t()) ::
              {:ok, TestSuiteRun.t()}
              | {:error, Ecto.Changeset.t()}
              | {:error, :error_parsing_junit_file}
  def parse_junit_file(test_suite, report_file, commit) do
    case Floki.parse_document(report_file, attributes_as_maps: true) do
      {:ok, [{:pi, "xml", _opts}, {"testsuites", %{}, test_suites}]} ->
        test_suite_starting_values =
          %{
            execution_time_seconds: Decimal.new(0),
            number_of_tests: 0,
            number_of_errors: 0,
            number_of_failures: 0,
            number_of_skipped: 0
          }

        {all_test_runs, seed, test_suite_totals} =
          Enum.reduce(test_suites, {[], nil, test_suite_starting_values}, fn {"testsuite", _properties, test_cases},
                                                                             {acc_tests, acc_seed, acc_totals} ->
            %{testsuite_properties: testsuite_properties, tests: tests} =
              Enum.reduce(test_cases, %{testsuite_properties: %{}, tests: []}, fn
                {
                  "properties",
                  _info,
                  [
                    {"property", %{"name" => "date", "value" => date}, []},
                    {"property", %{"name" => "seed", "value" => seed}, []}
                  ]
                },
                %{testsuite_properties: _testsuite_properties, tests: _tests} = acc ->
                  %{acc | testsuite_properties: %{date: date, seed: seed}}

                {"testcase", testcase_info, details},
                %{testsuite_properties: testsuite_properties, tests: tests} = _acc ->
                  tests =
                    [
                      Map.merge(
                        %{
                          class_name: testcase_info["classname"],
                          file_name: testcase_info["file"],
                          test_name: testcase_info["name"],
                          execution_time_seconds: convert_to_decimal(testcase_info["time"])
                        },
                        add_status(details)
                      )
                      | tests
                    ]

                  %{
                    testsuite_properties: testsuite_properties,
                    tests: tests
                  }
              end)

            # the seed is the same for all test files in the test suite
            new_seed = acc_seed || testsuite_properties.seed

            new_totals =
              Enum.reduce(tests, acc_totals, fn test_run, totals ->
                %{
                  execution_time_seconds: Decimal.add(totals.execution_time_seconds, test_run.execution_time_seconds),
                  number_of_tests: totals.number_of_tests + 1,
                  number_of_errors: totals.number_of_errors + if(test_run.status == :errored, do: 1, else: 0),
                  number_of_failures: totals.number_of_failures + if(test_run.status == :failed, do: 1, else: 0),
                  number_of_skipped: totals.number_of_skipped + if(test_run.status == :skipped, do: 1, else: 0)
                }
              end)

            {acc_tests ++ tests, new_seed, new_totals}
          end)

        %{
          test_suite_id: test_suite.id,
          commit: commit,
          seed: seed,
          test_runs: all_test_runs
        }
        |> Map.merge(test_suite_totals)
        |> TestSuiteRun.changeset()
        |> Repo.insert()

      error ->
        Logger.error("Error parsing junit file: #{inspect(error)}")
        {:error, :error_parsing_junit_file}
    end
  end

  defp add_status([{"failure", %{"message" => failure_message}, [stacktrace]}]) do
    %{
      status: :failed,
      info: %{message: failure_message, stacktrace: stacktrace}
    }
  end

  defp add_status([{"error", %{"message" => error_message}, [stacktrace]}]) do
    %{
      status: :errored,
      info: %{message: error_message, stacktrace: stacktrace}
    }
  end

  defp add_status([{"skipped", %{"message" => skipped_message}, []}]) do
    %{
      status: :skipped,
      info: %{message: skipped_message}
    }
  end

  defp add_status([]) do
    %{
      status: :passed
    }
  end

  defp convert_to_decimal(time_in_seconds_string) do
    time_in_seconds_string
    |> Decimal.new()
    |> Decimal.normalize()
  end
end
