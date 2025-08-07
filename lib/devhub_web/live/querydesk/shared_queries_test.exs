defmodule DevhubWeb.Live.QueryDesk.SharedQueriesTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  test "view with no data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/querydesk/shared-queries")
    assert html =~ "Shared queries"
    assert html =~ "All shared queries"
    assert html =~ "Shared by me"
    assert html =~ "Shared with me"
  end

  test "shared by me", %{conn: conn, user: user, organization: organization} do
    %{organization_users: [organization_user]} =
      insert(:user, organization_users: [build(:organization_user, organization: organization)])

    role = insert(:role, organization: organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: shared_query_id} =
      insert(:shared_query,
        created_by_user_id: user.id,
        database_id: credential.database.id,
        organization_id: organization.id
      )

    insert(:object_permission,
      shared_query_id: shared_query_id,
      organization_user_id: organization_user.id,
      permission: :read
    )

    insert(:object_permission,
      shared_query_id: shared_query_id,
      role_id: role.id,
      permission: :read
    )

    # showing on shared by me page
    {:ok, _view, html} = live(conn, ~p"/querydesk/shared-queries?filter=shared_by_me")
    assert html =~ "SELECT * FROM users"
    # shared with column should show when there is permissions
    assert html =~ "Shared with"
    assert html =~ role.name

    # not showing on shared with me page
    {:ok, _view, html} = live(conn, ~p"/querydesk/shared-queries?filter=shared_with_me")
    refute html =~ "SELECT * FROM users"
  end

  test "shared with me", %{conn: conn, user: user, organization: organization} do
    [organization_user] = user.organization_users
    %{id: user_2_id} = insert(:user)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: shared_query_id} =
      insert(:shared_query,
        created_by_user_id: user_2_id,
        database_id: credential.database.id,
        organization_id: organization.id
      )

    insert(:object_permission,
      shared_query_id: shared_query_id,
      organization_user_id: organization_user.id,
      permission: :read
    )

    # showing on shared with me page
    {:ok, _view, html} = live(conn, ~p"/querydesk/shared-queries?filter=shared_with_me")
    assert html =~ "SELECT * FROM users"

    # not showing on shared by me page
    {:ok, _view, html} = live(conn, ~p"/querydesk/shared-queries?filter=shared_by_me")
    refute html =~ "SELECT * FROM users"
  end

  test "can delete if you created the query", %{conn: conn, user: user, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    insert(:shared_query,
      created_by_user_id: user.id,
      database_id: credential.database.id,
      organization_id: organization.id
    )

    {:ok, view, _html} = live(conn, ~p"/querydesk/shared-queries?filter=all")
    assert has_element?(view, "button[phx-click='delete_shared_query']")
  end

  @tag with_permissions: %{super_admin: true}
  test "can delete if you are a super admin", %{conn: conn, user: user, organization: organization} do
    [organization_user] = user.organization_users
    %{id: fake_user_id} = insert(:user)

    credential = insert(:database_credential, database: build(:database, organization: organization))

    shared_query =
      insert(:shared_query,
        created_by_user_id: fake_user_id,
        database_id: credential.database.id,
        organization_id: organization.id
      )

    insert(:object_permission,
      shared_query_id: shared_query.id,
      organization_user_id: organization_user.id,
      permission: :read
    )

    {:ok, view, html} = live(conn, ~p"/querydesk/shared-queries?filter=all")
    assert has_element?(view, "button[phx-click='delete_shared_query']")

    # testing delete event

    assert html =~ shared_query.query

    html =
      view
      |> element(~s(button[phx-value-id="#{shared_query.id}"]))
      |> render_click()

    refute html =~ shared_query.query
  end

  @tag with_permissions: %{super_admin: false}
  test "can't delete without correct permissions", %{conn: conn, user: user, organization: organization} do
    [organization_user] = user.organization_users
    %{id: fake_user_id} = insert(:user)

    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: shared_query_id} =
      insert(:shared_query,
        created_by_user_id: fake_user_id,
        database_id: credential.database.id,
        organization_id: organization.id
      )

    insert(:object_permission,
      shared_query_id: shared_query_id,
      organization_user_id: organization_user.id,
      permission: :read
    )

    {:ok, view, _html} = live(conn, ~p"/querydesk/shared-queries?filter=all")
    refute has_element?(view, "button[phx-click='delete_shared_query']")
  end

  test "fail to delete", %{conn: conn, user: user, organization: organization} do
    changeset = SharedQuery.changeset(%SharedQuery{}, %{expires_at: DateTime.utc_now()})
    credential = insert(:database_credential, database: build(:database, organization: organization))

    shared_query =
      insert(:shared_query,
        created_by_user_id: user.id,
        database_id: credential.database.id,
        organization_id: organization.id
      )

    {:ok, view, _html} = live(conn, ~p"/querydesk/shared-queries?filter=all")

    expect(QueryDesk, :delete_shared_query, fn _shared_query_id ->
      {:error, changeset}
    end)

    html =
      view
      |> element(~s(button[phx-value-id="#{shared_query.id}"]))
      |> render_click()

    assert html =~ "Failed to delete shared query"
  end
end
