defmodule DevhubWeb.Live.Dashboards.ViewDashboardTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Dashboards.Schemas.Dashboard.QueryPanel

  test "can view a dashboard", %{conn: conn, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    # we expect the first panel to be run automatically without inputs
    %{panels: [%{id: panel_id, inputs: []}, %{id: panel_2_id, inputs: [_input]}]} =
      dashboard =
      :dashboard
      |> build(
        organization: organization,
        panels: [
          %{title: "Data view", details: %QueryPanel{query: "SELECT * FROM users", credential_id: credential.id}},
          %{
            title: "Data view with input",
            inputs: [%{key: "user_id", description: "the user id"}],
            details: %QueryPanel{
              query: "SELECT * FROM users WHERE id = '${user_id}'",
              credential_id: credential.id
            }
          }
        ]
      )
      |> Devhub.Repo.insert!()

    assert {:ok, view, html} = live(conn, ~p"/dashboards/#{dashboard.id}/view")

    assert html =~ dashboard.name

    event = "panel-#{panel_id}:custom_event"

    assert_push_event(view, ^event, %{
      type: "queryResult",
      data: %{
        columns: [
          "id",
          "name",
          "picture",
          "external_id",
          "provider",
          "timezone",
          "inserted_at",
          "updated_at",
          "email",
          "enable_query_completion",
          "preferences",
          "proxy_password"
        ],
        command: :select,
        num_rows: 0,
        rows: []
      }
    })

    # run the second query by passing the input
    view
    |> element(~s(form[phx-submit="run_query"]))
    |> render_submit(%{
      "user_id" => "1"
    })

    event = "panel-#{panel_2_id}:custom_event"

    assert_push_event(view, ^event, %{
      type: "queryResult",
      data: %{
        columns: [
          "id",
          "name",
          "picture",
          "external_id",
          "provider",
          "timezone",
          "inserted_at",
          "updated_at",
          "email",
          "enable_query_completion",
          "preferences",
          "proxy_password"
        ],
        command: :select,
        num_rows: 0,
        rows: []
      }
    })

    # actions
    view
    |> element(~s(button[phx-click="export"][phx-value-panel_id=#{panel_id}]))
    |> render_click()

    event = "panel-#{panel_id}:custom_event"
    assert_push_event(view, ^event, %{type: "export", data: %{}})
  end
end
