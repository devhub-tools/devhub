defmodule Devhub.Users.Actions.DeleteTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Team

  test "delete_team/2" do
    %{id: organization_id} = insert(:organization)
    %{id: team_id} = team = insert(:team, organization_id: organization_id)

    assert {:ok, %Team{id: ^team_id}} = Users.get_team(team_id)

    assert {:ok, %Team{}} = Users.delete_team(team)

    assert {:error, :team_not_found} = Users.get_team(team_id)
  end
end
