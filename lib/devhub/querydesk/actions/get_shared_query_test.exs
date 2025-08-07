defmodule Devhub.QueryDesk.Actions.GetSharedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  test "success" do
    organization = insert(:organization)
    %{id: user_id} = insert(:user)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: shared_query_id} =
      insert(:shared_query,
        database_id: credential.database_id,
        created_by_user_id: user_id,
        organization_id: organization.id
      )

    assert {:ok, %SharedQuery{id: ^shared_query_id, created_by_user_id: ^user_id}} =
             QueryDesk.get_shared_query(id: shared_query_id)
  end

  test "expired" do
    organization = insert(:organization)
    %{id: user_id} = insert(:user)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    %{id: shared_query_id} =
      insert(:shared_query,
        database_id: credential.database_id,
        created_by_user_id: user_id,
        organization_id: organization.id,
        expires_at: DateTime.add(DateTime.utc_now(), -1, :day)
      )

    assert {:error, :shared_query_expired} = QueryDesk.get_shared_query(id: shared_query_id)
  end
end
