defmodule Devhub.QueryDesk.Actions.SaveSharedQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.SharedQuery

  test "save" do
    %{id: organization_id} = organization = insert(:organization)

    %{database_id: database_id} =
      insert(:database_credential,
        default_credential: true,
        database: build(:database, organization: organization)
      )

    %{id: user_id} = insert(:user)

    params = %{
      "expires_at" => DateTime.add(DateTime.utc_now(), 1, :hour),
      "include_results" => "false",
      "query" => "select * FROM roles",
      "restricted_access" => "false",
      "database_id" => database_id,
      "created_by_user_id" => user_id,
      "organization_id" => organization_id
    }

    assert {:ok, %SharedQuery{}} = QueryDesk.save_shared_query(params)
  end
end
