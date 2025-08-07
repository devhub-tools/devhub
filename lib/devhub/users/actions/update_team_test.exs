defmodule Devhub.Users.Actions.UpdateTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Team

  test "update_team/2" do
    %{id: organization_id} = insert(:organization)
    team = insert(:team, organization_id: organization_id, name: "a")
    params = %{name: "b"}

    assert {:ok, %Team{name: "b"}} =
             Users.update_team(team, params)
  end
end
