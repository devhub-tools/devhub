defmodule Devhub.TerraDesk.Actions.CreateWorkspaceTest do
  use Devhub.DataCase, async: true

  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Workspace

  test "success" do
    %{id: organization_id} = organization = insert(:organization)
    repository = insert(:repository, organization: organization)

    assert {:ok,
            %Workspace{
              name: "server-config",
              organization_id: ^organization_id
            }} =
             TerraDesk.create_workspace(%{
               name: "server-config",
               organization_id: organization_id,
               repository_id: repository.id
             })
  end

  test "errors if organization is nil" do
    assert {
             :error,
             %Ecto.Changeset{
               errors: [
                 name: {"can't be blank", [validation: :required]},
                 repository_id: {"can't be blank", [validation: :required]}
               ]
             }
           } = TerraDesk.create_workspace(%{})
  end
end
