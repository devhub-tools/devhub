defmodule Devhub.Workflows.Actions.ListRunsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows

  test "list_workflows/1" do
    organization = insert(:organization)
    workflow = insert(:workflow, organization: organization)

    {:ok, run} = Workflows.run_workflow(workflow, %{})
    Workflows.run_workflow(workflow, %{})
    Workflows.run_workflow(workflow, %{})

    other_workflow = insert(:workflow, organization: organization)
    Workflows.run_workflow(other_workflow, %{})

    result = Workflows.list_runs(workflow.id)
    assert length(result) == 3

    # pending excludes runs that have already completed
    assert {:ok, %{status: :failed}} = Workflows.continue(run)
    result = Workflows.list_runs(workflow.id, filters: [status: "pending"])
    assert length(result) == 2
  end
end
