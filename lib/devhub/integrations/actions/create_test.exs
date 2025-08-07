defmodule Devhub.Integrations.Actions.CreateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations
  alias Devhub.Integrations.Schemas.Integration

  describe "create/1" do
    test "successfully create integration" do
      %{id: organization_id} = organization = insert(:organization)

      params = %{
        organization_id: organization_id,
        organization: organization,
        provider: :github,
        external_id: Ecto.UUID.generate()
      }

      assert {:ok, %Integration{}} = Integrations.create(params)
    end

    test "fail to create integration/ missing required fields" do
      %{id: organization_id} = organization = insert(:organization)

      assert {:error, %Ecto.Changeset{errors: [provider: {"can't be blank", [validation: :required]}]}} =
               Integrations.create(%{
                 organization_id: organization_id,
                 organization: organization
               })
    end
  end
end
