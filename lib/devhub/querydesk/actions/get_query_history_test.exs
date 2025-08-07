defmodule Devhub.QueryDesk.Actions.GetQueryHistoryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    organization = insert(:organization)
    user = insert(:user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    query =
      insert(:query,
        user: user,
        organization: organization,
        credential: credential,
        executed_at: DateTime.utc_now()
      )

    assert [%{id: query.id, query: query.query, executed_at: query.executed_at}] ==
             QueryDesk.get_query_history(credential.database_id, user_id: user.id, query: {:like, query.query})
  end
end
