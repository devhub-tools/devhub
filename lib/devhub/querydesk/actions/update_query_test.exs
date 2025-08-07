defmodule Devhub.QueryDesk.Actions.UpdateQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        user: build(:user),
        credential: build(:database_credential, database: build(:database, organization: organization))
      )

    assert {:ok, _query} =
             QueryDesk.update_query(query, %{
               query: "select * from querydesk_databases",
               executed_at: DateTime.utc_now(),
               failed: true
             })
  end
end
