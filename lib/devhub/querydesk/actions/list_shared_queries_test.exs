defmodule Devhub.QueryDesk.Actions.ListSharedQueriesTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  test "users can list queries" do
    %{id: organization_id} = organization = insert(:organization)
    fake_user = insert(:user)

    %{organization_users: [testing_access_organization_user]} =
      insert(:user, organization_users: [build(:organization_user, organization: organization)])

    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: id} =
      insert(:shared_query,
        query: "a",
        database_id: credential.database_id,
        created_by_user_id: fake_user.id,
        organization_id: organization_id
      )

    assert [
             %SharedQuery{id: ^id}
           ] =
             testing_access_organization_user
             |> QueryDesk.Actions.ListSharedQueries.list_shared_queries()
             |> Enum.sort_by(& &1.query)
  end
end
