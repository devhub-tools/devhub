defmodule DevhubWeb.Live.Coverbot.TestReports.TestSuiteTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Coverbot

  test "renders test suite page with flaky and skipped tests", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)
    test_suite_id = "test_suite_123"

    test_suite =
      build(:test_suite,
        id: test_suite_id,
        name: "example_test_suite",
        organization: organization,
        repository: repository,
        test_suite_runs: [],
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      )

    commit = build(:commit, repository: repository, organization: organization)

    test_suite_run =
      build(:test_suite_run,
        organization: organization,
        repository: repository,
        test_suite: test_suite,
        commit: commit
      )

    flaky_test =
      %{
        test_name: "flaky_test_example",
        class_name: "TestModule",
        failure_count: 3,
        first_failure_at: ~U[2024-01-01 10:00:00Z],
        commit_sha: "abc123",
        info: %{
          message: "Test failed randomly",
          stacktrace: "at TestModule.flaky_test_example(TestModule.java:42)"
        }
      }

    skipped_test =
      build(:test_run,
        test_suite_run: test_suite_run,
        status: :skipped,
        class_name: "SkippedTestModule",
        test_name: "skipped_test_example",
        info: %{message: "Test was skipped due to configuration", stacktrace: nil}
      )

    expect(Coverbot, :get_test_suite, 2, fn ^test_suite_id ->
      {:ok, test_suite}
    end)

    expect(Coverbot, :get_flaky_tests, fn ^test_suite_id, 10 ->
      [flaky_test]
    end)

    expect(Coverbot, :get_skipped_tests, fn ^test_suite_id ->
      [skipped_test]
    end)

    {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports/#{test_suite_id}")

    # Wait for async assigns to resolve
    current_html = render_async(view, 1000)

    assert current_html =~ "flaky_test_example"
    assert current_html =~ "TestModule"

    assert current_html =~ "skipped_test_example"
    assert current_html =~ "SkippedTestModule"

    assert has_element?(view, "#flaky-tests-data")
    assert has_element?(view, "#skipped-tests-data")

    # flaky table
    flaky_html = view |> element("#flaky-tests-data") |> render()
    assert flaky_html =~ "flaky_test_example"
    assert flaky_html =~ "TestModule"
    assert flaky_html =~ ~s(href=\"https://github.com/devhub-tools/devhub/commit/abc123\")

    # skipped table
    skipped_html = view |> element("#skipped-tests-data") |> render()
    assert skipped_html =~ "skipped_test_example"
    assert skipped_html =~ "SkippedTestModule"
    assert skipped_html =~ ~s(href=\"https://github.com/devhub-tools/devhub/commit/#{commit.sha}\")

    parsed = Floki.parse_document!(current_html)

    assert parsed |> Floki.find("#flaky-tests-drawer > div") |> length() == 1
    assert parsed |> Floki.find("#skipped-tests-drawer > div") |> length() == 1

    # flaky drawer contains error sections and message
    assert current_html =~ "flaky-tests-drawer"
    assert current_html =~ "Error message"
    assert current_html =~ "Stacktrace"
    assert current_html =~ "Test failed randomly"

    # skipped drawer contains info section and message
    assert current_html =~ "skipped-tests-drawer"
    assert current_html =~ "Info"
    assert current_html =~ "Test was skipped due to configuration"

    # row click handlers target the correct drawer content via phx-click JS selector
    flaky_drawer_id = "#flaky-test-flaky_test_example-TestModule-drawer-content"
    skipped_drawer_id = "#skipped-test-skipped_test_example-SkippedTestModule-drawer-content"

    assert parsed |> Floki.find(~s(#flaky-tests-data td[phx-click*="#{flaky_drawer_id}"])) |> length() >= 1
    assert parsed |> Floki.find(~s(#skipped-tests-data td[phx-click*="#{skipped_drawer_id}"])) |> length() >= 1
  end

  test "renders empty state when no flaky or skipped tests", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)
    test_suite_id = "clean_test_suite_123"

    test_suite =
      build(
        :test_suite,
        id: test_suite_id,
        name: "clean_test_suite",
        organization: organization,
        repository: repository,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        test_suite_runs: []
      )

    stub(Coverbot, :get_test_suite, fn ^test_suite_id ->
      {:ok, test_suite}
    end)

    stub(Coverbot, :get_flaky_tests, fn ^test_suite_id, 10 ->
      []
    end)

    stub(Coverbot, :get_skipped_tests, fn ^test_suite_id ->
      []
    end)

    {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports/#{test_suite_id}")

    # Wait for async assigns to resolve
    current_html = render_async(view, 1000)

    assert current_html =~ "No flaky tests in the past 10 days"
    assert current_html =~ "No skipped tests in the past 10 days"

    refute has_element?(view, "#flaky-tests-data")
    refute has_element?(view, "#skipped-tests-data")
  end

  test "shows loading states for flaky and skipped tests on initial render", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)
    test_suite_id = "loading_test_suite_123"

    test_suite =
      build(
        :test_suite,
        id: test_suite_id,
        name: "loading_test_suite",
        organization: organization,
        repository: repository,
        test_suite_runs: []
      )

    expect(Coverbot, :get_test_suite, 2, fn ^test_suite_id ->
      {:ok, test_suite}
    end)

    stub(Coverbot, :get_flaky_tests, fn ^test_suite_id, 10 ->
      []
    end)

    stub(Coverbot, :get_skipped_tests, fn ^test_suite_id ->
      []
    end)

    {:ok, _view, html} = live(conn, ~p"/coverbot/test-reports/#{test_suite_id}")

    assert html =~ "Loading flaky tests"
    assert html =~ "Loading skipped tests"
  end

  test "shows failed state when flaky loading fails", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)
    test_suite_id = "failed_test_suite_123"

    test_suite =
      build(
        :test_suite,
        id: test_suite_id,
        name: "failed_test_suite",
        organization: organization,
        repository: repository
      )

    expect(Coverbot, :get_test_suite, 2, fn ^test_suite_id ->
      {:ok, test_suite}
    end)

    expect(Coverbot, :get_flaky_tests, fn ^test_suite_id, 10 ->
      raise "flaky failure"
    end)

    expect(Coverbot, :get_skipped_tests, fn ^test_suite_id ->
      raise "skipped failure"
    end)

    assert {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports/#{test_suite_id}")

    html = render_async(view, 1000)

    assert html =~ "There was an error loading flaky tests"
    assert html =~ "There was an error loading skipped tests"
  end

  test "shows failed state when skipped loading fails", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)
    test_suite_id = "failed_skipped_test_suite_123"

    test_suite =
      build(
        :test_suite,
        id: test_suite_id,
        name: "failed_skipped_test_suite",
        organization: organization,
        repository: repository
      )

    expect(Coverbot, :get_test_suite, 2, fn ^test_suite_id ->
      {:ok, test_suite}
    end)

    expect(Coverbot, :get_flaky_tests, fn ^test_suite_id, 10 ->
      raise "flaky failure"
    end)

    expect(Coverbot, :get_skipped_tests, fn ^test_suite_id ->
      raise "skipped failure"
    end)

    assert {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports/#{test_suite_id}")

    html = render_async(view, 1000)

    assert html =~ "There was an error loading flaky tests"
    assert html =~ "There was an error loading skipped tests"
  end
end
