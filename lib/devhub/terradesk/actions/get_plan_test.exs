defmodule Devhub.TerraDesk.Actions.GetPlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "get plan" do
    assert {:error, :plan_not_found} = TerraDesk.get_plan(id: "not-found")

    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    %{id: plan_id} = insert(:plan, workspace: workspace, organization: organization)

    assert {:ok, %Plan{id: ^plan_id}} = TerraDesk.get_plan(id: plan_id)
  end
end
