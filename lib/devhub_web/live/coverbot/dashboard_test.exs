defmodule DevhubWeb.Live.Coverbot.DashboardTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "LIVE /coverbot", %{conn: conn, organization: organization} do
    conn = get(conn, ~p"/coverbot")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    assert html =~ "No coverage reported yet, create an api key to get started."

    insert(:coverage,
      organization_id: organization.id,
      repository:
        build(:repository,
          organization_id: organization.id,
          owner: "coverbot-io",
          name: "coverbot"
        ),
      ref: "1234567",
      percentage: Decimal.new(10)
    )

    {:ok, _view, html} = live(conn)

    assert html =~ "coverbot-io"
  end
end
