defmodule Devhub.QueryDesk.Actions.DeleteSavedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    organization = insert(:organization)

    query = insert(:saved_query, organization: organization)

    assert {:ok, _query} = QueryDesk.delete_saved_query(query)
  end
end
