defmodule Devhub.TerraDesk.Actions.GetWorkspacesTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace

  test "get workspace" do
    organization = insert(:organization)
    other_organization = insert(:organization)

    %{id: workspace_id} =
      insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    assert [%Workspace{id: ^workspace_id}] = TerraDesk.get_workspaces()
    assert [%Workspace{id: ^workspace_id}] = TerraDesk.get_workspaces(organization_id: organization.id)
    assert [] = TerraDesk.get_workspaces(organization_id: other_organization.id)
  end
end
