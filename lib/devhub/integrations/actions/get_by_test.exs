defmodule Devhub.Integrations.Actions.GetByTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations
  alias Devhub.Integrations.Schemas.Integration

  describe "get_by/1" do
    test "sucessfully gets integration" do
      %{id: organization_id} = organization = insert(:organization)

      %{id: integration_id} =
        insert(:integration, organization: organization, organization_id: organization_id)

      assert {:ok, %Integration{id: ^integration_id}} = Integrations.get_by(id: integration_id)
    end

    test "integration not found" do
      assert {:error, :integration_not_found} = Integrations.get_by(id: "invalid id")
    end
  end
end
