defmodule Devhub.TerraDesk.Actions.GetWorkspaceTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace

  test "get workspace" do
    assert {:error, :workspace_not_found} = TerraDesk.get_workspace(id: "not-found")

    organization = insert(:organization)

    %{id: workspace_id} =
      insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    assert {:ok, %Workspace{id: ^workspace_id}} = TerraDesk.get_workspace(id: workspace_id)
  end
end
