defmodule Devhub.QueryDesk.Actions.CanRunQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Query

  test "can't run already executed query" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        user: build(:user),
        credential:
          build(:database_credential, database: build(:database, organization: organization), reviews_required: 1),
        executed_at: DateTime.utc_now()
      )

    refute QueryDesk.can_run_query?(query)
  end

  test "can run a query if no reviews required" do
    organization = insert(:organization)

    query =
      insert(:query,
        organization: organization,
        user: build(:user),
        credential:
          build(:database_credential, database: build(:database, organization: organization), reviews_required: 0)
      )

    assert QueryDesk.can_run_query?(query)
  end

  test "can run a query with correct approvals" do
    organization = insert(:organization)
    user = insert(:user)

    organization_user =
      insert(:organization_user, organization: organization, user: user)

    approving_user = insert(:user)
    approving_organization_user = insert(:organization_user, organization: organization, user: approving_user)

    query =
      insert(:query,
        organization: organization,
        user: user,
        credential:
          build(:database_credential,
            database:
              build(:database,
                organization: organization,
                permissions: [
                  build(:object_permission, organization_user: organization_user, permission: :approve),
                  build(:object_permission, organization_user: approving_organization_user, permission: :approve)
                ]
              ),
            reviews_required: 1
          )
      )

    # no approvals
    refute QueryDesk.can_run_query?(query)

    insert(:query_approval, query: query, approving_user: build(:user))
    insert(:query_approval, query: query, approving_user: user)

    # approval must be from allowed user (not self and has approver permission)
    refute QueryDesk.can_run_query?(query)

    insert(:query_approval, query: query, approving_user: approving_user)
    assert QueryDesk.can_run_query?(query)

    # can't run udpated query
    query = query |> Query.changeset(%{query: "something"}) |> Repo.update!()
    refute QueryDesk.can_run_query?(query)
  end

  test "can run a query with correct role approvals" do
    organization = insert(:organization)

    user = insert(:user)
    insert(:organization_user, organization: organization, user: user)

    approving_user = insert(:user)
    approving_organization_user = insert(:organization_user, organization: organization, user: approving_user)
    role = insert(:role, organization: organization, name: "approver")
    insert(:organization_user_role, organization_user: approving_organization_user, role: role)

    query =
      insert(:query,
        organization: organization,
        user: user,
        credential:
          build(:database_credential,
            database:
              build(:database,
                organization: organization,
                permissions: [
                  build(:object_permission, role: role, permission: :approve)
                ]
              ),
            reviews_required: 1
          )
      )

    # no approvals
    refute QueryDesk.can_run_query?(query)

    insert(:query_approval, query: query, approving_user: build(:user))
    insert(:query_approval, query: query, approving_user: user)

    # approval must be from allowed user (not self and has approver permission)
    refute QueryDesk.can_run_query?(query)

    insert(:query_approval, query: query, approving_user: approving_user)
    assert QueryDesk.can_run_query?(query)

    # can't run udpated query
    query = query |> Query.changeset(%{query: "something"}) |> Repo.update!()
    refute QueryDesk.can_run_query?(query)
  end
end
