defmodule DevhubWeb.Live.Dashboards.EditDashboardTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Dashboards.Schemas.Dashboard.QueryPanel

  test "can edit a dashboard", %{conn: conn, organization: organization} do
    dashboard = insert(:dashboard, organization: organization)
    assert {:ok, view, html} = live(conn, ~p"/dashboards/#{dashboard.id}")

    assert html =~ dashboard.name
    refute html =~ "Panel title"

    assert view
           |> element(~s(button[phx-click="add_panel"]))
           |> render_click() =~ "Panel title"

    html =
      view
      |> element(~s(form[phx-change=update]))
      |> render_change(%{
        dashboard: %{
          name: "New name",
          panels: %{"0" => %{title: "Data view", inputs: %{"0" => %{key: "key", description: "description"}}}}
        }
      })

    assert html =~ "New name"
    assert html =~ "Data view"
    assert html =~ "key"
    assert html =~ "description"
  end

  test "credential search", %{conn: conn, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    dashboard =
      :dashboard
      |> build(
        organization: organization,
        panels: [%{title: "Data view", details: %QueryPanel{query: "SELECT * FROM users", credential_id: credential.id}}]
      )
      |> Devhub.Repo.insert!()

    assert {:ok, view, _html} = live(conn, ~p"/dashboards/#{dashboard.id}")

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["dashboard", "panels", 0, "details", "credential_search"],
      dashboard: %{
        panels: %{
          "0" => %{
            details: %{query: "SELECT * FROM users", credential_search: "other"}
          }
        }
      }
    })

    refute has_element?(view, ~s([data-testid="#{credential.id}-option"]))

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["dashboard", "panels", 0, "details", "credential_search"],
      dashboard: %{
        panels: %{
          "0" => %{
            details: %{query: "SELECT * FROM users", credential_search: credential.database.name}
          }
        }
      }
    })

    assert has_element?(view, ~s([data-testid="#{credential.id}-option"]))
  end
end
