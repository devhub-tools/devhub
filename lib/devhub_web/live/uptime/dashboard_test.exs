defmodule DevhubWeb.Live.Uptime.DashboardTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "LIVE /", %{conn: conn, organization: organization} do
    service = insert(:uptime_service, organization: organization)

    conn = get(conn, "/uptime")

    assert html_response(conn, 200)

    assert {:ok, view, _html} = live(conn)

    assert render_hook(view, :window_resize, %{width: 1000})

    assert render_async(view) =~ service.name
  end
end
