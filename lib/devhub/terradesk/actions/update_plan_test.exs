defmodule Devhub.TerraDesk.Actions.UpdatePlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "success" do
    %{id: organization_id} = organization = insert(:organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        name: "old"
      )

    assert %{id: plan_id, status: :queued} =
             plan =
             insert(:plan, workspace: workspace, organization: organization, status: :queued)

    assert {:ok,
            %Plan{
              id: ^plan_id,
              status: :failed,
              log: "failed",
              organization_id: ^organization_id
            }} =
             TerraDesk.update_plan(plan, %{status: :failed, log: "failed"})
  end
end
