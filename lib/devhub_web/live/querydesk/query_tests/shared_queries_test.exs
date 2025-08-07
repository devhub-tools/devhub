defmodule DevhubWeb.Live.QueryDesk.QueryTests.SharedQueriesTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  test "create shared query with include results", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    %{query: query_string} = query = insert(:query, organization: organization, credential: credential)

    {:ok, view, _html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    # open modal
    results = %{
      "columns" => ["id"],
      "command" => "select",
      "num_rows" => 2,
      "rows" => [
        [["usr_01JRK0PQ95BDPB29Q8011REGVY", "text", true]],
        [["usr_01JRK0Q3DXB8728HQD2YWDR58S", "text", true]]
      ]
    }

    render_hook(view, "show_shared_query_modal", %{query: query.query, data: %{results: results}})

    # submit shared query form
    view
    |> element(~s(form[phx-submit="create_shared_query"]))
    |> render_submit()

    assert [
             %SharedQuery{
               query: ^query_string,
               include_results: true,
               expires: false,
               results: shared_results
             }
           ] = SharedQuery |> Repo.all() |> Repo.preload(:permissions)

    assert results == shared_results |> :brotli.decode() |> elem(1) |> Jason.decode!()
  end

  test "can't click shared query if no query selected", %{conn: conn, organization: organization} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    {:ok, view, _html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    render_hook(view, "show_shared_query_modal", %{query: ""})

    refute has_element?(view, "#shared-query-modal")
  end

  test "handles failure to save shared query", %{conn: conn, organization: organization} do
    changeset = SharedQuery.changeset(%SharedQuery{}, %{expires_at: DateTime.utc_now()})

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    %{query: query_string} = insert(:query, organization: organization, credential: credential)

    {:ok, view, _html} = live(conn, ~p"/querydesk/databases/#{credential.database_id}/query")

    # open modal
    render_hook(view, "show_shared_query_modal", %{query: query_string})

    expect(Devhub.QueryDesk, :save_shared_query, fn _shared_query -> {:error, changeset} end)

    view
    |> element(~s(form[phx-submit="create_shared_query"]))
    |> render_submit()
  end

  describe "load from shared query link" do
    test "success", %{conn: conn, user: user, organization: organization} do
      [organization_user] = user.organization_users

      credential =
        insert(:database_credential,
          default_credential: true,
          database: build(:database, organization: organization)
        )

      {:ok, results} =
        %{
          "columns" => ["id"],
          "command" => "select",
          "num_rows" => 2,
          "rows" => [
            [["usr_01JRK0PQ95BDPB29Q8011REGVY", "text", true]],
            [["usr_01JRK0Q3DXB8728HQD2YWDR58S", "text", true]]
          ]
        }
        |> Jason.encode!()
        |> :brotli.encode(%{quality: 5})

      shared_query =
        insert(:shared_query,
          created_by_user_id: user.id,
          database_id: credential.database_id,
          organization_id: organization.id,
          restricted_access: true,
          results: results,
          include_results: true,
          permissions: [
            build(:object_permission, organization_user_id: organization_user.id, permission: :read)
          ]
        )

      {:ok, view, _html} =
        live(conn, ~p"/querydesk/databases/#{credential.database_id}/query?shared_query_id=#{shared_query.id}")

      # Verify the set_query event is pushed
      chunk = Base.encode64(results)
      assert_push_event(view, "set_query", %{"query" => "SELECT * FROM users"})
      assert_push_event(view, "query-result-table:custom_event", %{type: "streamResult", data: %{chunk: ^chunk}})
    end

    test "expired", %{conn: conn, user: user, organization: organization} do
      [organization_user] = user.organization_users

      credential =
        insert(:database_credential,
          default_credential: true,
          database: build(:database, organization: organization)
        )

      shared_query =
        insert(:shared_query,
          created_by_user_id: user.id,
          database_id: credential.database_id,
          organization_id: organization.id,
          restricted_access: true,
          expires: true,
          expires_at: DateTime.add(DateTime.utc_now(), -1, :hour)
        )

      insert(:object_permission,
        shared_query_id: shared_query.id,
        organization_user_id: organization_user.id,
        permission: :read
      )

      assert {:error,
              {:live_redirect, %{to: "/querydesk/shared-queries", flash: %{"error" => "This shared query has expired."}}}} =
               live(conn, ~p"/querydesk/databases/#{credential.database_id}/query?shared_query_id=#{shared_query.id}")
    end
  end
end
