defmodule Devhub.Coverbot.TestReports.Actions.GetSkippedTestsTest do
  use Devhub.DataCase

  alias Devhub.Coverbot

  test "get_skipped_tests/1" do
    organization = insert(:organization)
    repository = insert(:repository, organization: organization)
    test_suite = insert(:test_suite, organization: organization, repository: repository)
    commit = insert(:commit, repository: repository, organization: organization)

    test_suite_run_1 =
      insert(:test_suite_run,
        test_suite: test_suite,
        commit: commit,
        inserted_at: ~U[2024-01-01 10:00:00Z]
      )

    # latest run we use to check for skipped tests
    test_suite_run_2 =
      insert(:test_suite_run,
        test_suite: test_suite,
        commit: commit,
        inserted_at: ~U[2024-01-02 10:00:00Z]
      )

    # tests in first ignored run (test_suite_run_1)
    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "old_skipped_test",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_1,
      test_name: "consistently_skipped",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    # tests in latest run (test_suite_run_2)
    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "passing_test",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "failing_test",
      class_name: "TestModule",
      status: :failed,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "skipped_test_1",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "skipped_test_2",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "consistently_skipped",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    # different class name, same test name
    insert(:test_run,
      test_suite_run: test_suite_run_2,
      test_name: "skipped_test_1",
      class_name: "AnotherTestModule",
      status: :skipped,
      inserted_at: ~U[2024-01-02 10:00:00Z]
    )

    skipped_tests = Coverbot.get_skipped_tests(test_suite.id)

    assert length(skipped_tests) == 4

    test_identifiers =
      skipped_tests
      |> Enum.map(fn test_run ->
        {test_run.test_name, test_run.class_name}
      end)
      |> Enum.sort()

    expected_identifiers = [
      {"consistently_skipped", "TestModule"},
      {"skipped_test_1", "AnotherTestModule"},
      {"skipped_test_1", "TestModule"},
      {"skipped_test_2", "TestModule"}
    ]

    assert test_identifiers == expected_identifiers
  end

  test "get_skipped_tests/1 returns empty list when no skipped tests in latest run" do
    organization = insert(:organization)
    repository = insert(:repository, organization: organization)
    test_suite = insert(:test_suite, organization: organization, repository: repository)
    commit = insert(:commit, repository: repository, organization: organization)

    test_suite_run =
      insert(:test_suite_run,
        test_suite: test_suite,
        commit: commit,
        inserted_at: ~U[2024-01-01 10:00:00Z]
      )

    # Older run with a skipped test; should be ignored
    older_test_suite_run =
      insert(:test_suite_run,
        test_suite: test_suite,
        commit: commit,
        inserted_at: ~U[2023-12-31 10:00:00Z]
      )

    insert(:test_run,
      test_suite_run: older_test_suite_run,
      test_name: "older_skipped_test",
      class_name: "TestModule",
      status: :skipped,
      inserted_at: ~U[2023-12-31 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run,
      test_name: "passing_test",
      class_name: "TestModule",
      status: :passed,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    insert(:test_run,
      test_suite_run: test_suite_run,
      test_name: "failing_test",
      class_name: "TestModule",
      status: :failed,
      inserted_at: ~U[2024-01-01 10:00:00Z]
    )

    skipped_tests = Coverbot.get_skipped_tests(test_suite.id)

    assert skipped_tests == []
  end
end
