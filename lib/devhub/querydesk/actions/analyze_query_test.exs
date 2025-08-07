defmodule Devhub.QueryDesk.Actions.AnalyzeQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "returns query plan" do
    user = insert(:user)

    credential =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: build(:organization))
      )

    query =
      insert(:query,
        user: user,
        organization: credential.database.organization,
        credential: credential,
        query: "SELECT * FROM users u LEFT JOIN organization_users ou ON ou.user_id = u.id"
      )

    assert {:ok, %{plan: plan}} = QueryDesk.analyze_query(query)

    assert %{
             "Execution Time" => _execution_time,
             "Plan" => _plan,
             "Planning" => _planning,
             "Planning Time" => _planning_time,
             "Triggers" => []
           } = plan
  end
end
