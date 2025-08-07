defmodule Devhub.QueryDesk.Actions.GetQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query

  test "get_query/1" do
    organization = insert(:organization)

    assert {:error, :query_not_found} = QueryDesk.get_query(id: "not-found")

    query =
      insert(:query,
        organization: organization,
        credential: build(:database_credential, database: build(:database, organization: organization)),
        user: build(:user)
      )

    assert {:ok, %Query{}} = QueryDesk.get_query(id: query.id)
  end
end
