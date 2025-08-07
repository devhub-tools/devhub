defmodule Devhub.Workflows.Actions.ListWorkflowsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows

  test "list_workflows/1" do
    %{id: organization_id} = organization = insert(:organization)
    list = insert_list(3, :workflow, organization: organization)

    # Has Workflows
    result = Workflows.list_workflows(organization_id)
    result_ids = Enum.map(result, & &1.id)

    assert Enum.all?(list, fn workflow -> workflow.id in result_ids end)

    # No Workflows
    assert [] = Workflows.list_workflows("org_123")
  end
end
