defmodule Devhub.QueryDesk.Actions.ListSavedQueriesTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SavedQuery

  test "success" do
    organization = insert(:organization)

    %{organization_users: [organization_user]} =
      user = insert(:user, organization_users: [build(:organization_user, organization: organization)])

    _exclude_wrong_org = insert(:saved_query, organization: build(:organization), created_by_user_id: user.id)

    %{id: saved_query_id, query: query} =
      insert(:saved_query, organization: organization, created_by_user_id: user.id)

    assert [
             %SavedQuery{id: ^saved_query_id}
           ] = QueryDesk.list_saved_queries(organization_user)

    assert [
             %SavedQuery{id: ^saved_query_id}
           ] = QueryDesk.list_saved_queries(organization_user, filter: [query: {:like, query}])

    assert [] = QueryDesk.list_saved_queries(organization_user, filter: [query: {:like, "random"}])
  end
end
