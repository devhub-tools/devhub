defmodule Devhub.QueryDesk.Actions.PinDatabaseTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.UserPinnedDatabase

  test "success" do
    organization = insert(:organization)
    %{id: organization_user_id} = organization_user = insert(:organization_user, organization: organization)
    %{id: database_id} = database = insert(:database, organization: organization)

    assert {:ok, %UserPinnedDatabase{database_id: ^database_id, organization_user_id: ^organization_user_id}} =
             QueryDesk.pin_database(organization_user, database)
  end
end
