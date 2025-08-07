defmodule Devhub.Integrations.Linear.Actions.UpsertIssueTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Workflows.Schemas.Run

  test "triggers a workflow run" do
    organization = insert(:organization)
    integration = insert(:integration, organization: organization, provider: :linear)
    label = insert(:linear_label, organization: organization)

    workflow =
      insert(:workflow,
        organization: organization,
        trigger_linear_label_id: label.id,
        inputs: [%{key: "user_id", type: :integer}, %{key: "email", type: :string}]
      )

    issue_params = %{
      "id" => Ecto.UUID.generate(),
      "title" => "Trigger workflow",
      "description" => """
      Example issue description

      Workflow inputs:
      user_id: 123
      email: michael@devhub.tools
      """,
      "labels" => [%{"id" => label.external_id, "color" => label.color, "name" => label.name}]
    }

    %{id: issue_id} = Linear.upsert_issue(integration, issue_params)

    assert {:ok,
            %Run{
              id: workflow_run_id,
              input: %{"user_id" => 123, "email" => "michael@devhub.tools"},
              triggered_by_linear_issue_id: ^issue_id
            }} =
             Devhub.Workflows.get_run(workflow_id: workflow.id)

    assert_enqueued worker: Devhub.Workflows.Jobs.RunWorkflow, args: %{id: workflow_run_id}

    # does not trigger a workflow run if the issue is already triggered
    assert %{id: ^issue_id} = Linear.upsert_issue(integration, issue_params)

    assert {:ok, %Run{id: ^workflow_run_id}} = Devhub.Workflows.get_run(workflow_id: workflow.id)
  end
end
