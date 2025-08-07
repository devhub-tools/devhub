defmodule DevhubWeb.Live.QueryDesk.QueryTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.QueryDesk.Utils.GetConnectionPid
  alias Devhub.Repo
  alias Ecto.Adapters.SQL

  test "run a query", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, view, html} =
             live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    assert html =~ "Run query"

    view
    |> element(~s(button[phx-click="trigger_run_query"]))
    |> render_click()

    assert_push_event(view, "trigger_run_query", %{})

    # the editor will send the run_query event after trigger_run_query is clicked
    render_hook(view, "run_query", %{
      "query" => "SELECT * FROM schema_migrations ORDER BY version;",
      "selection" => nil
    })

    assert_push_event(view, "query-result-table:custom_event", %{type: "startStream", data: %{}})

    assert has_element?(view, "svg[data-testid=spinner]")

    send(view.pid, {:query_stream, :done})

    # data-table then calls the run-query http endpoint and lets LV know the number of rows it received
    assert render_hook(view, "query_finished", %{
             "numberOfRows" => 10
           }) =~ "ms\n          <span class=\"text-alpha-24 text-sm\">|</span> 10 rows"

    refute has_element?(view, "svg[data-testid=spinner]")

    # export
    view |> element(~s(button[phx-click="export"])) |> render_click()
    assert_push_event(view, "query-result-table:custom_event", %{type: "export", data: %{}})
  end

  test "run multiple queries", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, view, html} =
             live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    assert html =~ "Run query"

    view
    |> element(~s(button[phx-click="trigger_run_query"]))
    |> render_click()

    assert_push_event(view, "trigger_run_query", %{})

    # the editor will send the run_query event after trigger_run_query is clicked
    render_hook(view, "run_query", %{
      "query" => """
      SELECT * FROM schema_migrations ORDER BY version LIMIT 100;
      UPDATE users SET updated_at = now();
      """,
      "selection" => nil
    })

    assert_push_event(view, "query-result-table:custom_event", %{type: "startStream", data: %{}})

    assert has_element?(view, "svg[data-testid=spinner]")

    assert_push_event(
      view,
      "query-result-table:custom_event",
      %{type: "queryResult", data: %{results: ["select 100", "update 0"]}},
      2000
    )

    refute has_element?(view, "svg[data-testid=spinner]")
  end

  test "run a query with options", %{conn: conn, organization: organization} do
    database = insert(:database, organization: organization)

    insert(:database_credential,
      default_credential: true,
      database: database
    )

    admin_credential =
      insert(:database_credential,
        username: "admin",
        reviews_required: 1,
        database: database
      )

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{database.id}/query")

    assert render_hook(view, "show_query_options", %{
             "query" => "SELECT * FROM schema_migrations;",
             "selection" => nil
           }) =~ ~s(id="run-query-modal")

    modal = view |> element(~s(div[id=run-query-modal])) |> render()
    assert modal =~ "0 reviews required"
    refute modal =~ "Run automatically on approval"

    view
    |> element(~s(form[phx-change=update_query_options]))
    |> render_change(%{query: %{credential_id: admin_credential.id}})

    modal = view |> element(~s(div[id=run-query-modal])) |> render()
    assert modal =~ "1 review required"
    assert modal =~ "Run automatically on approval"

    assert render_hook(view, "run_query_with_options", %{
             query: %{
               credential_id: admin_credential.id,
               query: "SELECT * FROM schema_migrations;",
               timeout: 10,
               run_on_approval: false
             }
           }) =~ "Query is pending approval"
  end

  test "analyze query", %{conn: conn, organization: organization} do
    database = insert(:database, organization: organization)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: database
      )

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{database.id}/query")

    assert render_hook(view, "show_query_options", %{
             "query" => "SELECT * FROM users;",
             "selection" => nil
           }) =~ ~s(id="run-query-modal")

    assert {:error, {:live_redirect, %{kind: :push, to: "/querydesk/plan/" <> _query_id}}} =
             render_hook(view, "run_query_with_options", %{
               query: %{
                 credential_id: credential.id,
                 query: "SELECT * FROM users;",
                 timeout: 10,
                 run_on_approval: false,
                 analyze: true
               }
             })
  end

  test "save query", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    {:ok, view, html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    refute html =~ ~s(phx-submit="save_query")

    assert render_hook(view, "save_query", %{query: "SELECT * FROM users;", selection: nil}) =~
             ~s(phx-submit="create_saved_query")

    # update form
    view
    |> element(~s(form[phx-change=update_saved_query_form]))
    |> render_change(%{saved_query: %{private: "true"}})

    html =
      view
      |> element(~s(form[phx-submit=create_saved_query]))
      |> render_submit(%{saved_query: %{title: "My query", query: "SELECT * FROM users;"}})

    assert html =~ "Query saved successfully."
    refute html =~ ~s(phx-submit="create_saved_query")

    assert %SavedQuery{private: true} = Repo.get_by(SavedQuery, query: "SELECT * FROM users;")
  end

  test "handles error", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    {:ok, view, _html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    render_hook(view, "run_query", %{
      "query" => "SELECT * FROM not_found;",
      "selection" => nil
    })

    assert_push_event(view, "query-result-table:custom_event", %{type: "startStream", data: %{}})

    assert_push_event(
      view,
      "query-result-table:custom_event",
      %{type: "streamResult", data: %{chunk: _chuns}},
      1000
    )
  end

  test "can cancel running query", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    {:ok, view, _html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    render_hook(view, "run_query", %{
      "query" => "SELECT pg_sleep(10);",
      "selection" => nil
    })

    assert_push_event(view, "query-result-table:custom_event", %{type: "startStream", data: %{}})
    assert has_element?(view, "svg[data-testid=spinner]")

    {:ok, pid} = GetConnectionPid.get_connection_pid(credential)

    :timer.sleep(100)

    assert {:ok, %Postgrex.Result{rows: [["SELECT pg_sleep(10)"]]}} =
             SQL.query(pid, """
             SELECT query
             FROM pg_stat_activity
             WHERE query LIKE '%pg_sleep%' and query NOT LIKE '%pg_stat_activity%'
             """)

    view |> element(~s(button[phx-click="cancel_query"])) |> render_click()

    assert_push_event(view, "query-result-table:custom_event", %{type: "streamDone", data: %{}})
    refute has_element?(view, "svg[data-testid=spinner]")

    :timer.sleep(100)

    assert {:ok, %Postgrex.Result{rows: []}} =
             SQL.query(pid, """
             SELECT *
             FROM pg_stat_activity
             WHERE query LIKE '%pg_sleep%' and query NOT LIKE '%pg_stat_activity%'
             """)
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

    {:ok, _view, html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    # database has hero-star in css class
    assert [
             {
               "div",
               [_class, {"data-testid", ^database_id}],
               [
                 {"div", [_next_class], [{"div", [], ["My Database"]}, {"div", [{"class", _another_class}], []}]},
                 {"div", [], [{"span", [{"class", "hero-star-solid size-4 bg-yellow-500"}], []}]}
               ]
             }
           ] =
             html |> Floki.parse_fragment!() |> Floki.find("div[data-testid=#{database_id}]")

    # extra database has no hero-star in css class
    assert [
             {
               "div",
               [
                 _class_2,
                 {"data-testid", ^extra_database_id}
               ],
               [
                 {"div", [_next_class_2], [{"div", [], ["extra"]}, {"div", [{"class", _another_class_2}], []}]},
                 {"div", [], []}
               ]
             }
           ] =
             html |> Floki.parse_fragment!() |> Floki.find("div[data-testid=#{extra_database_id}]")
  end
end
