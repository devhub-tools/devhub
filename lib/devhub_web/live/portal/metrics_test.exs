defmodule DevhubWeb.Live.Portal.MetricsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "loads with no data", %{conn: conn} do
    conn = get(conn, "/portal/metrics")

    assert html_response(conn, 200)

    assert {:ok, _view, html} = live(conn)

    refute html =~ "Cycle time"
  end

  test "loads with team filter", %{conn: conn, organization: organization} do
    insert(:integration, organization: organization, provider: :github)
    team = insert(:team, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/portal/metrics?team_id=#{team.id}")

    assert render_async(view, 1000) =~ "Cycle time"
  end
end
