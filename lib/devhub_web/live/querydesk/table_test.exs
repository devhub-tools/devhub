defmodule DevhubWeb.Live.QueryDesk.TableTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "view data for postgres", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    conn = get(conn, ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations")
    assert html_response(conn, 200) =~ "Query view"
  end

  test "view sorted data for a table", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    conn = get(conn, ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations?order_by=inserted_at")

    {:ok, view, html} = live(conn)

    assert [
             {
               "data-table",
               [
                 {"id", "query-result-table"},
                 {"phx-hook", "DataTable"},
                 {"editable", "editable"},
                 {"filterable", "filterable"},
                 {"sortable", "sortable"},
                 {"primarykeyname", "version"},
                 {"orderby", ~s({"field":"inserted_at","direction":"asc"})},
                 {"changes", "{}"}
               ],
               []
             }
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(#query-result-table))

    assert [
             {
               "data-table",
               [
                 {"id", "query-result-table"},
                 {"phx-hook", "DataTable"},
                 {"editable", "editable"},
                 {"filterable", "filterable"},
                 {"sortable", "sortable"},
                 {"primarykeyname", "version"},
                 {"orderby", ~s({"field":"inserted_at","direction":"desc"})},
                 {"changes", "{}"}
               ],
               []
             }
           ] =
             view
             |> render_hook("sort", %{"field" => "inserted_at"})
             |> Floki.parse_fragment!()
             |> Floki.find(~s(#query-result-table))
  end

  test "editing", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    conn = get(conn, ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations")

    {:ok, view, _html} = live(conn)

    # stage changes is triggered by a webcomponent
    html =
      render_hook(view, "stage_changes", %{
        "primary_key_value" => "20240321034813",
        "inserted_at" => "2023-02-26 18:02:32"
      })

    assert html =~ "1 changed row"
    assert html =~ "Discard changes"

    assert render_hook(view, "stage_changes", %{
             "primary_key_value" => "20240705175436",
             "inserted_at" => "2023-02-26 18:02:32"
           }) =~ "2 changed rows"

    assert render_hook(view, "unstage_changes", %{
             "primary_key_value" => "20240705175436",
             "inserted_at" => "2023-02-26 18:02:32"
           }) =~ "1 changed row"

    # save staged changes
    refute view
           |> element(~s(button[phx-click="apply_changes"]))
           |> render_click() =~ "Discard changes"
  end

  test "star next to pinned databases", %{conn: conn, organization: organization, user: user} do
    %{organization_users: [%{id: organization_user_id}]} = user
    %{id: extra_database_id} = insert(:database, organization: organization, name: "extra")

    %{id: database_id} =
      database =
      insert(:database,
        organization: organization
      )

    insert(:user_pinned_database, organization_user_id: organization_user_id, database_id: database_id)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: database
      )

    {:ok, _view, html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations")

    assert [
             {
               "div",
               [{"class", "flex h-10 w-full items-center justify-between "}, {"data-testid", ^database_id}],
               [
                 {"div", [_class], [{"div", [], ["My Database"]}, {"div", [_next_div], []}]},
                 {"div", [], [{"span", [{"class", "hero-star-solid size-4 bg-yellow-500"}], []}]}
               ]
             }
           ] = html |> Floki.parse_fragment!() |> Floki.find("div[data-testid=#{database_id}]")

    assert [
             {
               "div",
               [{"class", "flex h-10 w-full items-center justify-between "}, {"data-testid", ^extra_database_id}],
               [
                 {"div", [_class_2], [{"div", [], ["extra"]}, {"div", [_next_div_2], []}]},
                 {"div", [], []}
               ]
             }
           ] =
             html |> Floki.parse_fragment!() |> Floki.find("div[data-testid=#{extra_database_id}]")
  end

  test "column filters", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    conn = get(conn, ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations")

    {:ok, view, _html} = live(conn)

    # triggered in webcomponent
    render_hook(view, "add_column_filter", %{field: "version"})

    view
    |> element(~s(form[phx-change="apply_filters"]))
    |> render_change(%{
      "form" => %{
        "filters" => %{
          "0" => %{
            "column" => "version",
            "operator" => "equals",
            "value" => "20240321034813"
          }
        }
      }
    })

    assert_patched(
      view,
      ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations?filters=version%3Aequals%3A20240321034813"
    )

    render_hook(view, "add_column_filter", %{field: "inserted_at"})

    view
    |> element(~s(form[phx-change="apply_filters"]))
    |> render_change(%{
      "form" => %{
        "filters" => %{
          "0" => %{
            "column" => "version",
            "operator" => "equals",
            "value" => "20240321034813"
          },
          "1" => %{
            "column" => "inserted_at",
            "operator" => "is_null"
          }
        }
      }
    })

    assert_patched(
      view,
      ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations?filters=version%3Aequals%3A20240321034813%2Cinserted_at%3Ais_null%3A"
    )

    view
    |> element(~s(button[phx-click="remove_column_filter"][phx-value-index="0"]))
    |> render_click()

    assert_patched(
      view,
      ~p"/querydesk/databases/#{credential.database_id}/table/schema_migrations?filters=inserted_at%3Ais_null%3A"
    )
  end
end
