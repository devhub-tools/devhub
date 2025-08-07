defmodule Devhub.QueryDesk.Actions.DeleteSharedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  test "success" do
    organization = insert(:organization)
    fake_user = insert(:user)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    shared_query =
      insert(:shared_query,
        database_id: credential.database_id,
        created_by_user_id: fake_user.id,
        organization_id: organization.id
      )

    assert {:ok, _query} = QueryDesk.delete_shared_query(shared_query)
    assert [] = Repo.all(SharedQuery)
  end
end
