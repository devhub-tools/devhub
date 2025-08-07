defmodule Devhub.Users.Actions.ListTeamsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "list_teams/1" do
    %{id: organization_id} = insert(:organization)
    %{id: organization_id_2} = insert(:organization)
    team = insert(:team, organization_id: organization_id, name: "a")
    team_2 = insert(:team, organization_id: organization_id, name: "b")
    insert(:team, organization_id: organization_id_2, name: "c")

    assert [^team, ^team_2] =
             Users.list_teams(organization_id)
  end
end
