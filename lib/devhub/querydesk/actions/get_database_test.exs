defmodule Devhub.QueryDesk.Actions.GetDatabaseTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Database

  test "success" do
    organization = insert(:organization)

    %{id: database_id} = insert(:database, organization: organization)

    assert {:ok, %Database{id: ^database_id}} = QueryDesk.get_database(id: database_id)
    assert {:error, :database_not_found} = QueryDesk.get_database(id: database_id, organization_id: "test")
  end
end
