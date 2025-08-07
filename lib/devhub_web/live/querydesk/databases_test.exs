defmodule DevhubWeb.Live.QueryDesk.DatabasesTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "list databases and add new", %{conn: conn, organization: organization} do
    agent = insert(:agent, organization: organization)
    insert(:database, organization: organization, agent: agent)
    insert(:database, organization: organization, group: "production")

    conn = get(conn, ~p"/querydesk")
    assert html_response(conn, 200) =~ "devhub_test"

    assert {:ok, _view, _html} = live(conn)
  end

  test "toggle pin flow", %{conn: conn, organization: organization} do
    insert(:organization_user, organization: organization)
    %{id: database_id} = insert(:database, organization: organization)
    %{id: database_id_extra} = insert(:database, organization: organization, name: "extra")

    assert {:ok, view, html} = live(conn, ~p"/querydesk")

    # make sure it's a gray star when not pinned
    assert [
             {"button", [_phx_click, {"phx-value-database_id", ^database_id_extra}, _class],
              [{"span", [{"class", "hero-star size-5 hover:bg-yellow-400 bg-gray-500"}], []}]},
             {"button", [_phx_click_2, {"phx-value-database_id", ^database_id}, _class_2],
              [{"span", [{"class", "hero-star size-5 hover:bg-yellow-400 bg-gray-500"}], []}]}
           ] = html |> Floki.parse_fragment!() |> Floki.find("button[phx-click=toggle_pin]")

    html =
      view
      |> element(~s(button[phx-value-database_id=#{database_id}]))
      |> render_click()

    assert [
             {"button",
              [
                _phx_click,
                {"phx-value-database_id", ^database_id},
                _class
              ], [{"span", [{"class", "hero-star-solid size-5 hover:bg-yellow-400 bg-yellow-500"}], []}]},
             {"button",
              [
                _phx_click_2,
                {"phx-value-database_id", ^database_id_extra},
                _class_2
              ], [{"span", [{"class", "hero-star size-5 hover:bg-yellow-400 bg-gray-500"}], []}]}
           ] = html |> Floki.parse_fragment!() |> Floki.find("button[phx-click=toggle_pin]")

    # make sure it unpinned when clicked again
    html =
      view
      |> element(~s(button[phx-value-database_id=#{database_id}]))
      |> render_click()

    assert [
             {"button", [_phx_click, {"phx-value-database_id", ^database_id_extra}, _class],
              [{"span", [{"class", "hero-star size-5 hover:bg-yellow-400 bg-gray-500"}], []}]},
             {"button", [_phx_click_2, {"phx-value-database_id", ^database_id}, _class_2],
              [{"span", [{"class", "hero-star size-5 hover:bg-yellow-400 bg-gray-500"}], []}]}
           ] = html |> Floki.parse_fragment!() |> Floki.find("button[phx-click=toggle_pin]")
  end

  test "database no name crashing bug", %{conn: conn, organization: organization} do
    insert(:organization_user, organization: organization)
    insert(:database, organization: organization, name: nil)

    assert {:ok, _view, html} = live(conn, ~p"/querydesk")

    assert html =~ "(New database)"
  end
end
