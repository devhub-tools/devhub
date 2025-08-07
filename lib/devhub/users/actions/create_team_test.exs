defmodule Devhub.Users.Actions.CreateTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Team

  test "create_team/2" do
    %{id: organization_id} = organization = insert(:organization)

    assert {:ok, %Team{name: "DevOps", organization_id: ^organization_id}} =
             Users.create_team("DevOps", organization)
  end
end
