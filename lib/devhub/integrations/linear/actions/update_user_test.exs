defmodule Devhub.Integrations.Linear.Actions.UpdateUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.User

  test "update_user/2" do
    organization = insert(:organization)
    %{id: user_id} = user = insert(:linear_user, organization: organization, name: "Michael")

    params = %{
      name: "Michael St Clair"
    }

    assert {:ok,
            %User{
              id: ^user_id,
              name: "Michael St Clair"
            }} = Linear.update_user(user, params)
  end
end
