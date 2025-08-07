defmodule Devhub.QueryDesk.Actions.UpdateSavedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    organization = insert(:organization)
    user = insert(:user)

    query = insert(:saved_query, organization: organization, created_by_user_id: user.id)

    assert {:ok, _query} =
             QueryDesk.update_saved_query(query, %{
               query: "select * from querydesk_databases"
             })
  end
end
