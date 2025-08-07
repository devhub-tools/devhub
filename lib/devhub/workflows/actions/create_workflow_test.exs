defmodule Devhub.Workflows.Actions.CreateWorkflowTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Workflow

  test "create_workflow" do
    %{id: organization_id} = organization = insert(:organization)
    name = "MFA Resets"

    # Create a dashboard
    assert {:ok, %Workflow{}} = Workflows.create_workflow(%{name: name, organization_id: organization.id})

    # Workflows names are unique per organization
    assert {:error,
            %Ecto.Changeset{
              errors: [
                name:
                  {"has already been taken",
                   [
                     constraint: :unique,
                     constraint_name: "workflows_organization_id_name_index"
                   ]}
              ]
            }} = Workflows.create_workflow(%{name: name, organization_id: organization.id})

    # Workflow names may be reused when dashboard is archived
    now = DateTime.utc_now()

    Repo.update_all(
      from(d in Workflow, where: d.organization_id == ^organization_id, update: [set: [archived_at: ^now]]),
      []
    )

    assert {:ok, %Workflow{}} = Workflows.create_workflow(%{name: name, organization_id: organization.id})
  end
end
