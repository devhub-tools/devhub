defmodule DevhubWeb.Components.QueryDesk.AiChatTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.AI

  test "can load conversation history", %{conn: conn, organization: organization} do
    insert(:integration, organization: organization, provider: :ai, access_token: "123")

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    database_id = credential.database.id

    assert {:ok, view, html} = live(conn, ~p"/querydesk/databases/#{database_id}/ai")

    assert html =~ "Start a conversation"

    assert_push_event(view, "load_from_local_storage", %{})

    # start conversation
    AI
    |> expect(:conversation_title, fn _organization, "get me all commits" ->
      {:ok, "Git Log"}
    end)
    |> expect(:recommend_query, fn _organization_user, ^database_id, _conversation ->
      {:ok, "select * from commits"}
    end)

    view
    |> element(~s(form[phx-submit="start_conversation"]))
    |> render_submit(%{question: "get me all commits"})

    html = render_async(view)
    assert html =~ "Git Log"
    assert html =~ "select * from commits"

    view
    |> element(~s(button[phx-click="insert_query"]))
    |> render_click()

    assert_push_event(view, "insert_query", %{"query" => "\nselect * from commits"})

    # new conversation
    html =
      view
      |> element(~s(button[phx-click="clear_conversation"]))
      |> render_click()

    assert_push_event(view, "load_from_local_storage", %{})

    assert html =~ "Start a conversation"
    refute html =~ "select * from commits"

    # search/select conversation
    assert view
           |> element(~s(form[phx-change="search_conversations"]))
           |> render_change(%{search: "commits"}) =~ "Git Log"

    assert view
           |> element(~s(li[phx-click="select_conversation"]))
           |> render_click() =~ "select * from commits"

    assert_push_event(view, "load_from_local_storage", %{})

    # recommend query
    expect(AI, :recommend_query, 1, fn _organization_user, ^database_id, _conversation ->
      {:ok, "select * from commits"}
    end)

    view
    |> element(~s(form[phx-submit="recommend_query"]))
    |> render_submit(%{question: "get me all commits"})
  end
end
