defmodule Devhub.Users.Actions.RemovePasskeyTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "success" do
    user = insert(:user)
    passkey = insert(:passkey, user: user)

    assert {:ok, _passkey} = Users.remove_passkey(user, passkey)
  end

  test "can't remove another user's passkey" do
    user = insert(:user)
    passkey = insert(:passkey, user: build(:user))

    assert {:error, :user_id_mismatch} = Users.remove_passkey(user, passkey)
  end
end
