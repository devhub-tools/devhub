defmodule DevhubWeb.Components.QueryDesk.QueryLibraryTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo
  alias Devhub.Shared.Schemas.Label
  alias Devhub.Shared.Schemas.LabeledObject

  test "can load query library", %{conn: conn, organization: organization} do
    %{id: saved_query_id, query: query_string} = saved_query = insert(:saved_query, organization: organization)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    changeset = SavedQuery.changeset(saved_query, %{})

    assert {:ok, view, html} = live(conn, ~p"/querydesk/databases/#{credential.database.id}/library")

    assert html =~ saved_query.title
    assert_push_event(view, "set_query", %{"query" => ""})

    refute view
           |> element(~s(form[phx-change=search_saved_queries]))
           |> render_change(%{search: "test"}) =~ saved_query.title

    assert view
           |> element(~s(form[phx-change=search_saved_queries]))
           |> render_change(%{search: "My query"}) =~ saved_query.title

    assert view
           |> element(~s(li[phx-click=select_query]))
           |> render_click()

    assert_push_event(view, "load_from_local_storage", %{"localStorageKey" => ^saved_query_id, "default" => ^query_string})

    # failed to delete the query
    expect(Devhub.QueryDesk, :delete_saved_query, fn _saved_query ->
      {:error, changeset}
    end)

    view
    |> element(~s(button[phx-click=delete_saved_query]))
    |> render_click()

    assert render(view) =~ "Failed to delete query."

    # successfully deletes the query

    assert view
           |> element(~s(button[phx-click=delete_saved_query]))
           |> render_click() =~ "Select a query"

    assert_patched(view, ~p"/querydesk/databases/#{credential.database_id}/library")

    refute Repo.get(SavedQuery, saved_query.id)
  end

  test "can load specific query", %{conn: conn, organization: organization, user: user} do
    %{id: saved_query_id, query: query_string} =
      saved_query =
      insert(:saved_query,
        organization: organization,
        created_by_user_id: user.id,
        title: "My query",
        query: """
        -- user_id: The ID of the user to select
        -- user_name: The name of the user to select
        SELECT * FROM users WHERE id = '${user_id}' and name = '${user_name}'
        """
      )

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{saved_query.id}")

    assert_push_event(view, "load_from_local_storage", %{"localStorageKey" => ^saved_query_id, "default" => ^query_string})

    # failing to update query
    assert view
           |> element(~s(form[phx-change=update_saved_query]))
           |> render_change(%{saved_query: %{title: ""}}) =~ "can&#39;t be blank"

    # successfully updates the query
    view
    |> element(~s(form[phx-change=update_saved_query]))
    |> render_change(%{saved_query: %{title: "Get user"}})

    assert %SavedQuery{title: "Get user"} = Repo.get(SavedQuery, saved_query.id)

    assert has_element?(view, ~s(input[name=user_id]))

    html =
      view
      |> element(~s(form[phx-change=update_variables]))
      |> render_change(%{user_id: user.id})

    # correctly adds the variable description to the input
    assert [
             {"form", _form_attrs,
              [
                {"div", [{"class", "flex flex-col gap-y-2"}],
                 [
                   _user_id_input,
                   {"span", [{"class", "text-alpha-64 text-xs"}],
                    ["\n            The ID of the user to select\n          "]}
                 ]},
                {"div", [{"class", "flex flex-col gap-y-2"}],
                 [
                   _user_name_input,
                   {"span", [{"class", "text-alpha-64 text-xs"}],
                    ["\n            The name of the user to select\n          "]}
                 ]}
              ]}
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(form[phx-change="update_variables"]))

    # testing to make sure variable was replaced
    expected_query_string = """
    -- user_id: The ID of the user to select
    -- user_name: The name of the user to select
    SELECT * FROM users WHERE id = '#{user.id}' and name = ''\
    """

    render_hook(view, "run_query", %{"query" => query_string, "selection" => nil})
    assert_push_event(view, "query-result-table:custom_event", %{type: "startStream", data: %{}})
    assert {:ok, %{query: ^expected_query_string}} = QueryDesk.get_query(user_id: user.id, is_system: false)

    # testing the update saved query flow
    assert render_hook(view, "save_query", %{"query" => "SELECT * FROM users"}) =~ "Query updated successfully."

    assert %SavedQuery{query: "SELECT * FROM users"} = Repo.get(SavedQuery, saved_query.id)
  end

  test "filtering in saved queries", %{conn: conn, organization: organization} do
    # saved query 1
    label = insert(:label, organization_id: organization.id)

    saved_query =
      insert(:saved_query,
        organization: organization,
        title: "My query",
        query: "SELECT * FROM users",
        labeled_objects: [build(:labeled_object, label: label, organization_id: organization.id)]
      )

    # saved query 2
    label_2 = insert(:label, name: "general", organization_id: organization.id)

    insert(:saved_query,
      organization: organization,
      title: "My query 2",
      query: "SELECT * FROM commits",
      labeled_objects: [build(:labeled_object, label: label_2, organization_id: organization.id)]
    )

    # saved query 3
    label_3 = insert(:label, name: "databases", organization_id: organization.id)

    insert(:saved_query,
      organization: organization,
      title: "My query 3",
      query: "SELECT * FROM integrations",
      labeled_objects: [build(:labeled_object, label: label_3, organization_id: organization.id)]
    )

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, view, html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{saved_query.id}")

    # checking queries are on page before filtering
    assert html =~ "SELECT * FROM users"
    assert html =~ "SELECT * FROM commits"
    assert html =~ "SELECT * FROM integrations"

    # adding label to label filter
    html =
      view
      |> element(~s(ul[data-testid="saved-queries-list"] div[phx-value-label_id="#{label_2.id}"]))
      |> render_click()

    # checking the filtering worked as expected
    refute html =~ "SELECT * FROM users"
    assert html =~ "SELECT * FROM commits"
    refute html =~ "SELECT * FROM integrations"

    # removing label from label filter
    html =
      view
      |> element(~s(div[data-testid="saved-queries-labels"] button[phx-value-remove_label="general"]))
      |> render_click()

    # checking the filtering was removed
    assert html =~ "SELECT * FROM users"
    assert html =~ "SELECT * FROM commits"
    assert html =~ "SELECT * FROM integrations"

    # testing filter by search
    html =
      view
      |> element(~s(form[phx-change=search_saved_queries]))
      |> render_change(%{search: "commi"})

    refute html =~ "SELECT * FROM users"
    assert html =~ "SELECT * FROM commits"
    refute html =~ "SELECT * FROM integrations"

    # manually add label to filter from saved queries modal
    html =
      view
      |> element(~s(#add-label-to-filter button[phx-value-label_id="#{label_2.id}"]))
      |> render_click()

    refute html =~ "SELECT * FROM users"
    assert html =~ "SELECT * FROM commits"
    refute html =~ "SELECT * FROM integrations"

    # removing label from modal
    view
    |> element(~s(#add-label-to-filter button[phx-value-remove_label="general"]))
    |> render_click()

    # testing search and label filters together

    # adding label to label filter
    view
    |> element(~s(ul[data-testid="saved-queries-list"] div[phx-value-label_id="#{label_2.id}"]))
    |> render_click()

    # adding search filter
    html =
      view
      |> element(~s(form[phx-change=search_saved_queries]))
      |> render_change(%{search: "use"})

    refute html =~ "SELECT * FROM users"
    refute html =~ "SELECT * FROM commits"
    refute html =~ "SELECT * FROM integrations"
  end

  test "label modal for selected query", %{conn: conn, organization: organization} do
    label_3 = insert(:label, organization_id: organization.id, name: "databases")
    label_2 = insert(:label, organization_id: organization.id, name: "general")
    label = insert(:label, organization_id: organization.id, name: "testing")

    saved_query =
      insert(:saved_query,
        organization: organization,
        query: "SELECT * FROM integrations",
        title: "get all from integrations"
      )

    saved_query_2 =
      insert(:saved_query,
        organization: organization,
        query: "SELECT * FROM users",
        title: "get all from users"
      )

    labeled_object =
      insert(:labeled_object,
        saved_query_id: saved_query_2.id,
        label_id: label.id,
        organization_id: organization.id
      )

    insert(:labeled_object,
      saved_query_id: saved_query_2.id,
      label_id: label_2.id,
      organization_id: organization.id
    )

    insert(:labeled_object,
      saved_query_id: saved_query_2.id,
      label_id: label_3.id,
      organization_id: organization.id
    )

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    changeset = LabeledObject.create_changeset(labeled_object, %{})

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{saved_query.id}")

    # selecting a query without any labels assigned
    html =
      view
      |> element(~s(li[phx-value-id=#{saved_query.id}]))
      |> render_click()

    # checking labels are displayed but not selected
    refute html |> Floki.find(~s(div[data-testid="selected-labels-title"])) |> Floki.text() =~ "LABELS"
    assert html =~ "ADD LABEL"

    # failing to add a label to the query
    expect(Devhub.Shared, :create_object_label, fn %{saved_query_id: _query_id, label_id: _label_id} ->
      {:error, changeset}
    end)

    view
    |> element(~s(#add-label div[data-testid="search-labels-form"] button[phx-value-label_id=#{label.id}]))
    |> render_click()

    assert render(view) =~ "Failed to add label to query."

    # add a label to the query
    html =
      view
      |> element(~s(div[data-testid="search-labels-form"] button[phx-value-label_id=#{label.id}]))
      |> render_click()
      |> Floki.parse_fragment!()

    # checking the selected label is displayed under selected labels and the other labels are not
    refute html |> Floki.find(~s(#add-label div[data-testid="selected-labels"])) |> Floki.text() =~ "databases"
    refute html |> Floki.find(~s(#add-label div[data-testid="selected-labels"])) |> Floki.text() =~ "general"
    assert html |> Floki.find(~s(#add-label div[data-testid="selected-labels"])) |> Floki.text() =~ "testing"

    # checking both unassigned labels are displayed under add existing label and the selected label is not
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "databases"
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "general"
    refute html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "testing"

    # removing label from the query
    html =
      view
      |> element(~s(#add-label div[data-testid="selected-labels"] button[phx-click="remove_object_label"]))
      |> render_click()
      |> Floki.parse_fragment!()

    # checking the selected label got removed successfully
    refute html |> Floki.find(~s(#add-label span[data-testid="selected-labels-title"])) |> Floki.text() =~ "LABELS"

    # testing search filters unassigned labels
    html =
      view
      |> element(~s(#add-label div[data-testid="search-labels-form"] form[phx-change=search_labels]))
      |> render_change(%{label_search: "general"})
      |> Floki.parse_fragment!()

    refute html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "databases"
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "general"
    refute html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "testing"

    # create a new selected label
    html =
      view
      |> element(~s(#add-label div[data-testid="search-labels-form"] form[phx-change=search_labels]))
      |> render_change(%{label_search: "new label"})

    assert html =~ "Create a new label"

    html =
      view
      |> element(~s(#add-label button[phx-value-label_name="new label"]))
      |> render_click()
      |> Floki.parse_fragment!()

    # checking the created label is displayed under selected labels
    assert html |> Floki.find(~s(#add-label div[data-testid="selected-labels"])) |> Floki.text() =~ "new label"
    assert html |> Floki.find(~s(#add-label span[data-testid="selected-labels-title"])) |> Floki.text() =~ "LABELS"

    # checking the created label got inserted into the database
    assert %Label{name: "new label"} = Repo.get_by(Label, name: "new label")

    # testing search within modal

    # all 3 labels are displayed under add label before search
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "databases"
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "general"
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "testing"

    # add search filter

    html =
      view
      |> element(~s(#add-label div[data-testid="search-labels-form"] form[phx-change=search_labels]))
      |> render_change(%{label_search: "general"})
      |> Floki.parse_fragment!()

    # only general label is displayed under add label after search
    refute html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "databases"
    assert html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "general"
    refute html |> Floki.find(~s(#add-label div[data-testid="unassigned-labels"])) |> Floki.text() =~ "testing"
  end

  test "private saved queries properly filtered", %{conn: conn, organization: organization, user: user} do
    private_query =
      insert(:saved_query,
        organization: organization,
        query: "SELECT * FROM users",
        title: "another user's private query",
        created_by_user_id: insert(:user).id,
        private: true
      )

    public_query =
      insert(:saved_query,
        organization: organization,
        query: "SELECT * FROM commits",
        title: "get all from commits",
        created_by_user_id: user.id
      )

    own_private_query =
      insert(:saved_query,
        organization: organization,
        query: "SELECT * FROM users",
        title: "my private query",
        created_by_user_id: user.id,
        private: true
      )

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, _view, html} = live(conn, ~p"/querydesk/databases/#{credential.database.id}/library")

    assert html =~ public_query.title
    assert html =~ own_private_query.title
    refute html =~ private_query.title
  end

  test "can only toggle query to private if its your own query", %{conn: conn, organization: organization, user: user} do
    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    my_query = insert(:saved_query, organization: organization, created_by_user_id: user.id)
    other_query = insert(:saved_query, organization: organization, created_by_user_id: insert(:user).id)

    assert {:ok, _view, html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{my_query.id}")

    assert html =~ "Private"

    assert {:ok, view, html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{other_query.id}")

    # not visible on the front end
    refute html =~ "Private"

    # not able to update private field
    view
    |> element(~s(form[phx-change=update_saved_query]))
    |> render_change(%{saved_query: %{private: true}})

    assert %SavedQuery{private: false} = Repo.get(SavedQuery, other_query.id)
  end

  test "bug- update query on existing query", %{conn: conn, organization: organization} do
    saved_query = insert(:saved_query, organization: organization, query: "SELECT * FROM users")

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    assert {:ok, view, _html} =
             live(conn, ~p"/querydesk/databases/#{credential.database.id}/library?query_id=#{saved_query.id}")

    render_hook(view, "save_query", %{"query" => "SELECT * FROM teams"})

    assert %SavedQuery{query: "SELECT * FROM teams"} = Repo.get(SavedQuery, saved_query.id)
  end
end
