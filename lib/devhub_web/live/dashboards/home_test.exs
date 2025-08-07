defmodule DevhubWeb.Live.Dashboards.HomeTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "shows call to action with no dashboards", %{conn: conn} do
    assert {:ok, view, html} = live(conn, ~p"/dashboards")

    # Placeholder
    assert html =~ "No dashboards"

    # Add dashboard button
    assert view
           |> element(~s([data-testid="add-dashboard-button"]), "Add dashboard")
           |> has_element?()
  end

  test "shows saved dashboards", %{conn: conn, organization: organization} do
    conn = get(conn, ~p"/dashboards")
    %{id: dashboard_id, name: dashboard_name} = insert(:dashboard, organization: organization)

    assert html_response(conn, 200)

    assert {:ok, view, html} = live(conn)

    assert html =~ dashboard_name

    # Link to dashboard edit page
    assert view
           |> element(~s(a[href="/dashboards/#{dashboard_id}"]))
           |> has_element?()

    # Link to dashboard view page
    assert view
           |> element(~s(a[href="/dashboards/#{dashboard_id}/view"]))
           |> has_element?()

    # Add dashboard button persists
    assert view
           |> element(~s([data-testid="add-dashboard-button"]), "Add dashboard")
           |> has_element?()
  end

  test "add dashboard", %{conn: conn} do
    assert {:ok, view, _html} = live(conn, ~p"/dashboards")

    assert view
           |> element(~s(form[data-testid="add-dashboard-form"]))
           |> render_submit(%{name: ""}) =~ "Failed to create dashboard"

    assert {:error, {:live_redirect, %{kind: :push, to: "/dashboards/" <> _id}}} =
             view
             |> element(~s(form[data-testid="add-dashboard-form"]))
             |> render_submit(%{name: "New dashboard"})
  end
end
