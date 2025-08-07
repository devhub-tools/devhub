defmodule Devhub.Agents.Actions.UpdateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Agents

  test "success" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    assert {:ok, %{name: "new name"}} = Agents.update(agent, %{name: "new name"})
  end

  test "can't update organization_id" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    assert {:ok, %{organization_id: ^organization_id}} = Agents.update(agent, %{organization_id: "test"})
  end
end
