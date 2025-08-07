defmodule Devhub.Workflows.Actions.GetWorkflowTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Workflow

  test "get_workflow/1" do
    %{id: id} = insert(:workflow)

    assert {:ok, %Workflow{id: ^id}} = Workflows.get_workflow(id: id)
    assert {:error, :workflow_not_found} = Workflows.get_workflow(id: "not-found")
  end
end
