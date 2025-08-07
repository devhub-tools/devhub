defmodule Devhub.TerraDesk.Actions.ApprovePlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "approve" do
    organization = insert(:organization)

    user = insert(:user)

    %{id: organization_user_id} =
      organization_user =
      insert(:organization_user, user: user, organization: organization, permissions: %{super_admin: true})

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        name: "old"
      )

    plan = insert(:plan, workspace: workspace, organization: organization, status: :queued)

    assert {:ok, %Plan{approvals: [%{organization_user_id: ^organization_user_id}]} = plan} =
             TerraDesk.approve_plan(plan, organization_user)

    user = insert(:user)

    # second approval
    %{id: second_organization_user_id} =
      organization_user =
      insert(:organization_user, user: user, organization: organization, permissions: %{super_admin: true})

    assert {:ok,
            %Plan{
              approvals: [
                %{organization_user_id: ^second_organization_user_id},
                %{organization_user_id: ^organization_user_id}
              ]
            }} =
             TerraDesk.approve_plan(plan, organization_user)
  end
end
