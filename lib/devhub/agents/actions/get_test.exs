defmodule Devhub.Agents.Actions.GetTest do
  use Devhub.DataCase, async: true

  alias Devhub.Agents

  test "success" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    assert {:ok, ^agent} = Agents.get(id: agent.id)
  end

  test "not found" do
    assert {:error, :agent_not_found} = Agents.get(id: "not-found")
  end
end
