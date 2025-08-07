defmodule Devhub.Agents.Actions.ListTest do
  use Devhub.DataCase, async: true

  alias Devhub.Agents

  test "success" do
    %{id: organization_id} = insert(:organization)
    agent = insert(:agent, organization_id: organization_id)

    # should not return as it belongs to a different org
    %{id: other_organization_id} = insert(:organization)
    insert(:agent, organization_id: other_organization_id)

    assert [^agent] = Agents.list(organization_id)
  end
end
