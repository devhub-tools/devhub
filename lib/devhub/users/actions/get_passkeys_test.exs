defmodule Devhub.Users.Actions.GetPasskeysTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "success" do
    user = insert(:user)
    %{id: passkey_id} = insert(:passkey, user: user)
    insert(:passkey, user: build(:user))

    assert [%{id: ^passkey_id}] = Users.get_passkeys(user)
  end
end
