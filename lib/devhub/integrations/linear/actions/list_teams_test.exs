defmodule Devhub.Integrations.Linear.Actions.ListTeamsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "list_teams/1" do
    organization = insert(:organization)
    other_organization = insert(:organization)

    linear_team_ids = 3 |> insert_list(:linear_team, organization: organization) |> Enum.map(& &1.id)
    insert(:linear_team, organization: other_organization)

    linear_teams = Linear.list_teams(organization.id)
    assert length(linear_teams) == 3
    assert Enum.all?(linear_teams, &(&1.id in linear_team_ids))
  end
end
