defmodule Devhub.QueryDesk.Jobs.CleanupExpiredSharedQueriesTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk.Jobs.CleanupExpiredSharedQueries
  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  test "deletes expired shared queries" do
    user = insert(:user)
    organization = insert(:organization)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    %{id: expired_id} =
      insert(:shared_query,
        created_by_user_id: user.id,
        database_id: credential.database_id,
        expires_at: DateTime.add(DateTime.utc_now(), -1, :day),
        organization_id: organization.id,
        expires: true
      )

    %{id: not_expired_id} =
      insert(:shared_query,
        created_by_user_id: user.id,
        database_id: credential.database_id,
        organization_id: organization.id,
        expires: true
      )

    %{id: never_expires_id} =
      insert(:shared_query,
        created_by_user_id: user.id,
        database_id: credential.database_id,
        organization_id: organization.id
      )

    assert [%SharedQuery{id: ^expired_id}, %SharedQuery{id: ^not_expired_id}, %SharedQuery{id: ^never_expires_id}] =
             Repo.all(SharedQuery)

    assert :ok = perform_job(CleanupExpiredSharedQueries, %{})
    assert [%SharedQuery{id: ^not_expired_id}, %SharedQuery{id: ^never_expires_id}] = Repo.all(SharedQuery)
  end
end
