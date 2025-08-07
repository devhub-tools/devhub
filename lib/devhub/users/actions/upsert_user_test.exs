defmodule Devhub.Users.Actions.UpsertUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.User

  test "upsert/1" do
    params = %{
      name: "michael",
      email: "#{Ecto.UUID.generate()}@devhub.tools",
      picture: "a1b2c3",
      external_id: "abcd1",
      provider: "github",
      timezone: "America/Denver"
    }

    assert {:ok,
            %User{
              id: id,
              name: "michael",
              picture: "a1b2c3",
              external_id: "abcd1",
              provider: "github",
              timezone: "America/Denver"
            }} = Users.upsert_user(params)

    assert {:ok,
            %User{
              id: ^id,
              name: "michael",
              picture: "a1b2c3",
              external_id: "abcd1",
              provider: "github",
              timezone: "America/Denver"
            }} = Users.upsert_user(params)
  end
end
