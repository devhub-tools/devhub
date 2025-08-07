defmodule Devhub.Users.Actions.AddToTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.TeamMember

  test "add_to_team/2" do
    organization = insert(:organization)
    %{id: team_id} = insert(:team, organization: organization)
    %{id: organization_user_id} = insert(:organization_user, organization: organization)

    assert {:ok, %TeamMember{organization_user_id: ^organization_user_id, team_id: ^team_id}} =
             Users.add_to_team(organization_user_id, team_id)
  end
end
