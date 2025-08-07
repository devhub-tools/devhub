defmodule Devhub.TerraDesk.Actions.GetRecentPlansTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "get recent plans" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    %{id: plan1_id} = insert(:plan, workspace: workspace, organization: organization)
    %{id: plan2_id} = insert(:plan, workspace: workspace, organization: organization)

    assert [%Plan{id: ^plan2_id}, %Plan{id: ^plan1_id}] = TerraDesk.get_recent_plans(workspace)
  end
end
