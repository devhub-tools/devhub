defmodule Devhub.Workflows.Actions.GetRunTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Run

  test "get_run/1" do
    workflow = insert(:workflow, steps: [])
    {:ok, %{id: run_id}} = Workflows.run_workflow(workflow, %{})

    assert {:ok, %Run{id: ^run_id}} = Workflows.get_run(id: run_id)
    assert {:error, :workflow_run_not_found} = Workflows.get_run(id: "not-found")
  end
end
