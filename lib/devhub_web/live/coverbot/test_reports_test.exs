defmodule DevhubWeb.Live.Coverbot.TestReportsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "no test report exists", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports")

    empty_test_suites_div =
      view
      |> element("#empty-test-suites")
      |> render()
      |> Floki.parse_fragment!()

    assert ["/settings/api-keys"] ==
             Floki.attribute(empty_test_suites_div, "href")

    assert Floki.text(empty_test_suites_div) =~
             "No test reports uploaded yet, create an api key to get started."
  end

  test "test reports exist", %{conn: conn, organization: organization} do
    repository = build(:repository, organization: organization)

    %{id: test_suite_1_id} =
      test_suite_1 =
      build(:test_suite,
        name: "test_suite_1",
        organization: organization,
        repository: repository
      )

    %{id: test_suite_2_id} =
      test_suite_2 =
      build(:test_suite,
        name: "test_suite_2",
        organization: organization,
        repository: repository
      )

    %{id: test_suite_run_1_id} =
      test_suite_run_1 =
      build(:test_suite_run,
        organization: organization,
        repository: repository,
        test_suite: test_suite_1,
        execution_time_seconds: Decimal.new("132.54"),
        number_of_tests: 436,
        number_of_failures: 1,
        number_of_skipped: 3
      )

    %{id: test_suite_run_2_id} =
      test_suite_run_2 =
      build(:test_suite_run,
        organization: organization,
        repository: repository,
        test_suite: test_suite_2,
        execution_time_seconds: Decimal.new("45.87"),
        number_of_tests: 43,
        number_of_failures: 0,
        number_of_skipped: 0
      )

    expect(Devhub.Coverbot, :list_test_report_stats, 2, fn ^organization ->
      [
        %{test_suite: test_suite_1, last_test_suite_run: test_suite_run_1},
        %{test_suite: test_suite_2, last_test_suite_run: test_suite_run_2}
      ]
    end)

    {:ok, view, _html} = live(conn, ~p"/coverbot/test-reports")

    refute has_element?(view, "#empty-test-suites")

    card_1 =
      view
      |> element("##{test_suite_1_id}-card")
      |> render()
      |> Floki.parse_fragment!()

    card_1_header =
      card_1
      |> Floki.find("##{test_suite_1_id}-test-suite-header")
      |> Floki.text()

    assert card_1_header =~ "devhub-tools"
    assert card_1_header =~ "devhub"
    assert card_1_header =~ "test_suite_1"

    assert card_1
           |> Floki.find("##{test_suite_1_id}-execution-time")
           |> Floki.text() =~ "132.54 s"

    assert card_1
           |> Floki.find("##{test_suite_run_1_id}-stat-number-of-tests")
           |> Floki.text() =~ "436"

    assert card_1
           |> Floki.find("##{test_suite_run_1_id}-stat-number-of-failures")
           |> Floki.text() =~ "1"

    assert card_1
           |> Floki.find("##{test_suite_run_1_id}-stat-number-of-skipped")
           |> Floki.text() =~ "3"

    card_2 =
      view
      |> element("##{test_suite_2_id}-card")
      |> render()
      |> Floki.parse_fragment!()

    card_2_header =
      card_2
      |> Floki.find("##{test_suite_2_id}-test-suite-header")
      |> Floki.text()

    assert card_2_header =~ "devhub-tools"
    assert card_2_header =~ "devhub"
    assert card_2_header =~ "test_suite_2"

    assert card_2
           |> Floki.find("##{test_suite_2_id}-execution-time")
           |> Floki.text() =~ "45.87 s"

    assert card_2
           |> Floki.find("##{test_suite_run_2_id}-stat-number-of-tests")
           |> Floki.text() =~ "43"

    assert card_2
           |> Floki.find("##{test_suite_run_2_id}-stat-number-of-failures")
           |> Floki.text() =~ "0"

    assert card_2
           |> Floki.find("##{test_suite_run_2_id}-stat-number-of-skipped")
           |> Floki.text() =~ "0"
  end
end
