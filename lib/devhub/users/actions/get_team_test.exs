defmodule Devhub.Users.Actions.GetTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Team

  test "get_team/1" do
    %{id: organization_id} = insert(:organization)
    %{id: team_id} = insert(:team, organization_id: organization_id)

    assert {:ok, %Team{id: ^team_id}} = Users.get_team(team_id)

    assert {:error, :team_not_found} = Users.get_team("invalid id")
  end
end
