defmodule Devhub.Integrations.Linear.Actions.UpdateLinearTeamTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Team

  test "update_user/2" do
    organization = insert(:organization)
    %{id: team_id} = insert(:team, organization: organization)
    linear_team = insert(:linear_team, organization: organization)

    params = %{
      team_id: team_id
    }

    assert {:ok,
            %Team{
              team_id: ^team_id
            }} = Linear.update_linear_team(linear_team, params)
  end
end
