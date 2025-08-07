defmodule Devhub.QueryDesk.Actions.SaveQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SavedQuery

  test "success" do
    organization = insert(:organization)
    user = insert(:user)

    assert {:ok, %SavedQuery{query: "select * from users"}} =
             QueryDesk.save_query(%{
               organization_id: organization.id,
               title: "My query",
               query: "select * from users",
               created_by_user_id: user.id,
               private: false
             })
  end
end
