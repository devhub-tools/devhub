defmodule Devhub.QueryDesk.Actions.UnpinDatabaseTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.UserPinnedDatabase
  alias Devhub.Repo

  test "success" do
    organization = insert(:organization)
    %{id: organization_user_id} = organization_user = insert(:organization_user, organization: organization)
    %{id: database_id} = database = insert(:database, organization: organization)
    user_pinned_database = insert(:user_pinned_database, organization_user: organization_user, database: database)

    # check that its in the database
    assert [%UserPinnedDatabase{database_id: ^database_id, organization_user_id: ^organization_user_id}] =
             Repo.all(UserPinnedDatabase)

    assert {:ok, %UserPinnedDatabase{database_id: ^database_id, organization_user_id: ^organization_user_id}} =
             QueryDesk.unpin_database(user_pinned_database)

    # check that its not in the database
    assert [] = Repo.all(UserPinnedDatabase)
  end
end
