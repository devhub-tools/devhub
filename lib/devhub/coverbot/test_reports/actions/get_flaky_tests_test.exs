defmodule Devhub.Coverbot.TestReports.Actions.GetFlakyTestsTest do
  use Devhub.DataCase

  alias Devhub.Coverbot

  test "get_flaky_tests/2" do
    organization = insert(:organization)
    repository = insert(:repository, organization: organization)
    test_suite = insert(:test_suite, organization: organization, repository: repository)
    commit = insert(:commit, repository: repository, organization: organization)

    test_suite_run_1 =
      insert(:test_suite_run, test_suite: test_suite, commit: commit, inserted_at: ~U[2024-01-01 10:00:00Z])

    test_suite_run_2 =
      insert(:test_suite_run, test_suite: test_suite, commit: commit, inserted_at: ~U[2024-01-02 10:00:00Z])

    test_suite_run_3 =
      insert(:test_suite_run, test_suite: test_suite, commit: commit, inserted_at: ~U[2024-01-03 10:00:00Z])

    test_suite_run_4 =
      insert(:test_suite_run, test_suite: test_suite, commit: commit, inserted_at: ~U[2024-01-04 10:00:00Z])

    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "always_passing",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "flaky",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "always_failing",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "Always fails", stacktrace: "always fail trace"},
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "failed_before_cutoff",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "random message", stacktrace: "random stacktrace"},
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    # this shouldn't be included in the results because it's before the cutoff, and even if the test name is the same, the class name is different
    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "flaky",
      class_name: "TestModule2",
      status: :failed,
      info: %{message: "random message", stacktrace: "random stacktrace"},
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "always_passing",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "flaky",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "Error A", stacktrace: "trace A"},
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "always_failing",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "random message 2", stacktrace: "random stacktrace 2"},
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "failed_before_cutoff",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_3,
      test_name: "always_passing",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-03 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_3,
      test_name: "flaky",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "Error B", stacktrace: "trace B"},
      inserted_at: ~U[2024-01-03 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_3,
      test_name: "always_failing",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "random message 3", stacktrace: "random stacktrace 3"},
      inserted_at: ~U[2024-01-03 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_3,
      test_name: "failed_before_cutoff",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-03 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_4,
      test_name: "always_passing",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-04 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_4,
      test_name: "flaky",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-04 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_4,
      test_name: "always_failing",
      class_name: "TestModule",
      status: :failed,
      info: %{message: "last always flaky message", stacktrace: "last always flaky stacktrace"},
      inserted_at: ~U[2024-01-04 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_4,
      test_name: "failed_before_cutoff",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-04 10:00:00Z]
    )

    assert [
             %{
               class_name: "TestModule",
               failure_count: 3,
               first_failure_at: always_failing_first_failure_datetime,
               test_name: "always_failing",
               info: %{"message" => "last always flaky message", "stacktrace" => "last always flaky stacktrace"}
             },
             %{
               class_name: "TestModule",
               failure_count: 2,
               first_failure_at: flaky_first_failure_datetime,
               test_name: "flaky",
               # returns info for the last run
               info: %{"message" => "Error B", "stacktrace" => "trace B"}
             }
           ] =
             Coverbot.get_flaky_tests(test_suite.id, 3)

    assert Timex.equal?(flaky_first_failure_datetime, ~U[2024-01-02 10:00:00Z])
    assert Timex.equal?(always_failing_first_failure_datetime, ~U[2024-01-01 10:00:00Z])
  end
end
