defmodule Devhub.Users.Actions.RemoveFromTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Repo
  alias Devhub.Users
  alias Devhub.Users.TeamMember

  test "remove_from_team/2" do
    %{id: organization_id} = insert(:organization)
    %{id: team_id} = insert(:team, organization_id: organization_id)
    %{id: org_user_id} = insert(:organization_user, organization_id: organization_id)
    %{id: team_member_id} = insert(:team_member, organization_user_id: org_user_id, team_id: team_id)

    assert {1, nil} =
             Users.remove_from_team(org_user_id, team_id)

    assert TeamMember |> Repo.get(team_member_id) |> is_nil()
  end
end
