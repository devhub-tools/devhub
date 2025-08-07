defmodule DevhubWeb.Live.QueryDesk.QueryPlanTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "view query plan", %{conn: conn, organization: organization, user: user} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    [plan] = "test/support/querydesk/example-plan.json" |> File.read!() |> Jason.decode!()

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: "SELECT * FROM users",
        plan: plan
      )

    assert {:ok, view, html} = live(conn, ~p"/querydesk/plan/#{query.id}")

    assert html =~ to_string(plan["Execution Time"])

    assert view
           |> element(~s(span[phx-click="set_mode"][phx-value-mode="duration"]))
           |> render_click() =~ "duration:"

    assert view
           |> element(~s(span[phx-click="set_mode"][phx-value-mode="rows"]))
           |> render_click() =~ "rows:"

    assert view
           |> element(~s(span[phx-click="set_mode"][phx-value-mode="cost"]))
           |> render_click() =~ "cost:"

    assert view
           |> element(".plan > ul > li > .plan-node")
           |> render_click() =~ "Limit Node"
  end
end
