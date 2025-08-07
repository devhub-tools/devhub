defmodule Devhub.QueryDesk.Actions.DeleteQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "success" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        user: build(:user, organization_users: [build(:organization_user, organization: organization)]),
        credential: build(:database_credential, database: build(:database, organization: organization))
      )

    assert {:ok, _query} = QueryDesk.delete_query(query, query.user)
  end

  test "can delete query with approvals" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        user: build(:user, organization_users: [build(:organization_user, organization: organization)]),
        credential: build(:database_credential, database: build(:database, organization: organization)),
        approvals: [build(:query_approval, approving_user: build(:user))]
      )

    assert {:ok, _query} = QueryDesk.delete_query(query, query.user)
  end

  test "can't delete someone else's query" do
    organization = build(:organization)

    query =
      build(:query,
        organization: organization,
        user: build(:user),
        credential: build(:database_credential, database: build(:database, organization: organization))
      )

    assert {:error, :not_allowed_to_delete_query} =
             QueryDesk.delete_query(
               query,
               build(:user, organization_users: [build(:organization_user, organization: organization)])
             )
  end

  test "can't delete query if it has been executed" do
    organization = build(:organization)

    query =
      build(:query,
        organization: organization,
        user: build(:user, organization_users: [build(:organization_user, organization: organization)]),
        credential: build(:database_credential, database: build(:database, organization: organization)),
        executed_at: DateTime.utc_now()
      )

    assert {:error, :not_allowed_to_delete_query} = QueryDesk.delete_query(query, query.user)
  end
end
