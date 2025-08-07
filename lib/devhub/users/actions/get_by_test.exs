defmodule Devhub.Users.Actions.GetByTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.User

  test "get_by/1" do
    organization = insert(:organization)
    %{id: user_id} = user = insert(:user, organization_users: [build(:organization_user, organization: organization)])

    assert {:ok, %User{id: ^user_id}} = Users.get_by(name: user.name)

    assert {:error, :user_not_found} = Users.get_by(name: "not found")
  end
end
