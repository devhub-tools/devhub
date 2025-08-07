defmodule DevhubWeb.Components.QueryDesk.QueryHistoryTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "can load query history", %{conn: conn, organization: organization, user: user} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    %{query: query_string} =
      query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        executed_at: DateTime.utc_now()
      )

    assert {:ok, view, html} = live(conn, ~p"/querydesk/databases/#{credential.database.id}/history")

    assert html =~ query.query
    assert_push_event(view, "set_query", %{"query" => ""})

    assert view
           |> element(~s(li[phx-value-id=#{query.id}]))
           |> render_click()

    assert_push_event(view, "set_query", %{"query" => ^query_string})

    refute view
           |> element(~s(form[phx-change=search_query_history]))
           |> render_change(%{search: "test"}) =~ query.query
  end
end
