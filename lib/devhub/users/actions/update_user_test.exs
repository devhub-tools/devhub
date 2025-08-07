defmodule Devhub.Users.Actions.UpdateUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.User

  test "update_user/2" do
    user = insert(:user, name: "Micael")
    params = %{name: "Michael"}

    assert {:ok, %User{name: "Michael"}} = Users.update_user(user, params)
  end
end
