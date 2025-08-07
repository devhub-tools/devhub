defmodule Devhub.Workflows.Actions.CancelRunTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Run

  test "cancel_run/1" do
    organization = insert(:organization)

    workflow = insert(:workflow, organization: organization, steps: [])

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    assert {:ok, %Run{status: :canceled}} = Workflows.cancel_run(run)
  end
end
