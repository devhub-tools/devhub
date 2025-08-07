defmodule DevhubWeb.Live.Portal.MyPortalTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "loads with no data", %{conn: conn} do
    conn = get(conn, "/")

    assert html_response(conn, 200)

    assert {:ok, _view, _html} = live(conn)
  end

  test "dev portal not activated", %{conn: conn, organization: organization} do
    Devhub.Users.update_organization(organization, %{license: %{products: [:querydesk]}})

    conn = get(conn, "/")

    assert redirected_to(conn, 302) == ~p"/querydesk"
  end
end
