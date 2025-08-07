defmodule Devhub.Workflows.Actions.UpdateWorkflowTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Step.ConditionAction
  alias Devhub.Workflows.Schemas.Workflow

  test "success" do
    organization = insert(:organization)
    workflow = insert(:workflow, organization: organization)

    assert {:ok,
            %Workflow{
              inputs: [%{key: "string", type: :string}],
              steps: [
                %{
                  order: 0,
                  action: %ConditionAction{condition: "true", when_false: :failed}
                }
              ]
            }} =
             Workflows.update_workflow(workflow, %{
               inputs: [%{key: "string", type: :string}],
               steps: [
                 %{
                   action: %{__type__: :condition, condition: "true", when_false: :failed}
                 }
               ]
             })
  end

  test "failure" do
    workflow = insert(:workflow)

    expect(Devhub.Repo, :update, fn changeset -> {:error, changeset} end)

    assert {:error, %Ecto.Changeset{}} =
             Workflows.update_workflow(workflow, %{inputs: [%{key: "string", type: :string}]})
  end
end
