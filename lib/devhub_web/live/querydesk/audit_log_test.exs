defmodule DevhubWeb.Live.QueryDesk.AuditLogTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  test "view audit queries", %{conn: conn, organization: organization, user: user} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        executed_at: DateTime.add(DateTime.utc_now(), -1, :day),
        query: "select * from schema_migrations;",
        comments: [build(:comment, created_by_user_id: user.id, organization: organization)]
      )

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    assert html =~ "query ran at"
    refute html =~ "query failed at"
    assert html =~ "This is a comment"

    query
    |> Query.changeset(%{failed: true})
    |> Repo.update!()

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    refute html =~ "query ran at"
    assert html =~ "query failed at"
  end

  test "filter users", %{conn: conn, organization: organization} do
    user =
      insert(:user,
        name: "bob",
        organization_users: [build(:organization_user, organization: organization, permissions: %{super_admin: true})]
      )

    user_2 =
      insert(:user,
        name: "billy",
        organization_users: [build(:organization_user, organization: organization, permissions: %{super_admin: true})]
      )

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    insert(:query,
      user: user,
      organization: credential.database.organization,
      credential: credential,
      executed_at: DateTime.utc_now(),
      query: "select * from schema_migrations;"
    )

    insert(:query,
      user: user_2,
      organization: credential.database.organization,
      credential: credential,
      executed_at: DateTime.utc_now(),
      query: "select * from users;"
    )

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)

    {:ok, view, _html} = live(conn)

    render_hook(view, "filter_users", %{name: "billy"})
    render_hook(view, "clear_filter")
    render_hook(view, "select_user", %{id: user_2.id})
    render_hook(view, "select_user", %{id: user_2.id})
  end

  test "filter databases", %{conn: conn, organization: organization} do
    insert(:database_credential,
      default_credential: true,
      database: build(:database, organization: organization)
    )

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)
    {:ok, view, _html} = live(conn)

    render_hook(view, "filter_databases", %{name: "Devh"})
  end

  test "select database", %{conn: conn, organization: organization} do
    %{id: database_id} = database = insert(:database, organization: organization)

    insert(:database_credential,
      default_credential: true,
      database: database
    )

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)
    {:ok, view, _html} = live(conn)

    render_hook(view, "select_database", %{id: database_id})
  end

  test "search queries", %{conn: conn, organization: organization} do
    insert(:database_credential,
      default_credential: true,
      database: build(:database, organization: organization)
    )

    conn = get(conn, ~p"/querydesk/audit-log")

    assert html_response(conn, 200)
    {:ok, view, _html} = live(conn)

    render_hook(view, "search_queries", %{query_search: "select"})
  end
end
