defmodule Devhub.QueryDesk.Actions.GetSavedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SavedQuery

  test "success" do
    organization = insert(:organization)

    assert {:error, :saved_query_not_found} = QueryDesk.get_saved_query(id: "not-found")

    query = insert(:saved_query, organization: organization)

    assert {:ok, %SavedQuery{}} = QueryDesk.get_saved_query(id: query.id)
  end
end
