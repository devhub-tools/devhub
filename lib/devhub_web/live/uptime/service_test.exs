defmodule DevhubWeb.Live.Uptime.ServiceTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Service
  alias DevhubProtos.RequestTracer.V1.TraceResponse

  test "new service can load", %{conn: conn, organization: organization} do
    service = insert(:uptime_service, organization: organization)
    conn = get(conn, "/uptime/services/#{service.id}")

    assert html_response(conn, 200)

    assert {:ok, _view, html} = live(conn)

    assert html =~ service.name
  end

  test "handles chart failure", %{conn: conn, organization: organization} do
    service = insert(:uptime_service, organization: organization)

    expect(Devhub.Uptime, :service_history_chart, fn _service, _start_date, _end_date ->
      raise "Failure"
    end)

    assert {:ok, view, _html} = live(conn, "/uptime/services/#{service.id}")

    render_async(view, 1000) =~ "Failed to load chart"
  end

  test "service with checks can load", %{conn: conn, organization: organization} do
    service =
      insert(:uptime_service,
        organization: organization,
        checks:
          build_list(4, :uptime_check,
            organization: organization,
            response_headers: [%{key: "my-header", value: "value"}]
          )
      )

    assert {:ok, view, _html} = live(conn, "/uptime/services/#{service.id}")

    assert render_hook(view, :window_resize, %{width: 1000})

    assert html =
             view
             |> render_async()
             |> Floki.parse_document!()

    # should have 2 checks in the table
    assert html
           |> Floki.find("#check-table tbody > tr")
           |> length() == 2

    # should have 2 check drawers
    assert html
           |> Floki.find("#check-drawer > div")
           |> length() == 2
  end

  test "filters work", %{conn: conn, organization: organization} do
    success_checks = build_list(2, :uptime_check, organization: organization)
    failure_checks = build_list(2, :uptime_check, organization: organization, status: "failure")

    checks = success_checks ++ failure_checks

    service =
      insert(:uptime_service,
        organization: organization,
        checks: checks
      )

    assert {:ok, view, _html} = live(conn, "/uptime/services/#{service.id}")

    # check failure
    view
    |> element(~s(form[phx-change=update_filters]))
    |> render_change(%{status: "failure"})

    html = view |> render_async() |> Floki.parse_document!()

    # expect only the 2 failure checks to show up
    assert [
             {"span", [{"class", "rounded p-1 py-0.5 bg-red-200 text-red-800"}], ["\n    failure\n  "]},
             {"span", [{"class", "rounded p-1 py-0.5 bg-red-200 text-red-800"}], ["\n    failure\n  "]}
           ] == Floki.find(html, "#check-table tbody > tr > td:first-child > div > span > div > span")

    # check success
    view
    |> element(~s(form[phx-change=update_filters]))
    |> render_change(%{status: "success"})

    html = view |> render_async() |> Floki.parse_document!()

    # expect only the 2 success checks to show up
    assert [
             {"span", [{"class", "rounded p-1 py-0.5 bg-green-200 text-green-800"}], ["\n    success\n  "]},
             {"span", [{"class", "rounded p-1 py-0.5 bg-green-200 text-green-800"}], ["\n    success\n  "]}
           ] == Floki.find(html, "#check-table tbody > tr > td:first-child > div > span > div > span")
  end

  test "infinite scrolling", %{conn: conn, organization: organization} do
    service = insert(:uptime_service, organization: organization)
    checks = insert_list(10, :uptime_check, organization: organization, service: service)
    most_recent_check = List.last(checks)

    assert {:ok, view, _html} = live(conn, "/uptime/services/#{service.id}")

    # multiple pages are kept on the page, we will scroll until most recent isn't visible then test going back
    assert view |> element("#check-table") |> render_async() =~ most_recent_check.id

    render_hook(view, "next_page")

    assert view |> element("#check-table") |> render_async() =~ most_recent_check.id

    render_hook(view, "next_page")

    assert view |> element("#check-table") |> render_async() =~ most_recent_check.id

    render_hook(view, "next_page")

    # no longer visible so now trigger prev page
    refute view |> element("#check-table") |> render_async() =~ most_recent_check.id

    render_hook(view, "prev_page")

    assert view |> element("#check-table") |> render_async() =~ most_recent_check.id
  end

  describe "test service" do
    test "call is successful", %{conn: conn, organization: organization} do
      %{id: service_id} =
        service =
        insert(:uptime_service,
          organization: organization,
          enabled: true,
          expected_status_code: "2xx"
        )

      conn = get(conn, "/uptime/services/#{service.id}")

      assert {:ok, view, _html} = live(conn)

      expect(Uptime, :check_service, fn %Service{id: ^service_id} ->
        {:ok, %TraceResponse{status_code: 200}}
      end)

      button_click_result =
        view
        |> element("button[data-testid=check-service-button]")
        |> render_click()

      assert button_click_result =~ "Connection successful: status code 200"
      refute button_click_result =~ "Error connecting"
    end

    test "call returns unexpected status code", %{conn: conn, organization: organization} do
      %{id: service_id} =
        service =
        insert(:uptime_service,
          organization: organization,
          enabled: true,
          expected_status_code: "2xx"
        )

      conn = get(conn, "/uptime/services/#{service.id}")

      assert {:ok, view, _html} = live(conn)

      expect(Uptime, :check_service, fn %Service{id: ^service_id} ->
        {:error, %TraceResponse{status_code: 503}}
      end)

      button_click_result =
        view
        |> element("button[data-testid=check-service-button]")
        |> render_click()

      assert button_click_result =~ "Error connecting: unexpected status code 503"
      refute button_click_result =~ "Connection successful"
    end

    test "call fails", %{conn: conn, organization: organization} do
      %{id: service_id} =
        service =
        insert(:uptime_service,
          organization: organization,
          enabled: true,
          expected_status_code: "2xx"
        )

      conn = get(conn, "/uptime/services/#{service.id}")

      assert {:ok, view, _html} = live(conn)

      expect(Uptime, :check_service, fn %Service{id: ^service_id} ->
        {:error, :timeout}
      end)

      button_click_result =
        view
        |> element("button[data-testid=check-service-button]")
        |> render_click()

      assert button_click_result =~ "Error connecting: :timeout"
      refute button_click_result =~ "Connection successful"
    end
  end
end
