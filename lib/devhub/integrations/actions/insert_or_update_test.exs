defmodule Devhub.Integrations.Actions.InsertOrUpdateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations
  alias Devhub.Integrations.Schemas.Integration

  describe "insert_or_update/2" do
    test "can create" do
      %{id: organization_id} = organization = insert(:organization)

      integration = %Integration{}

      attrs = %{
        provider: :github,
        external_id: Ecto.UUID.generate(),
        organization: organization,
        organization_id: organization_id
      }

      assert {:ok, %Integration{}} = Integrations.insert_or_update(integration, attrs)
    end

    test "can update" do
      %{id: organization_id} = organization = insert(:organization)

      %{id: int_id} =
        integration =
        insert(:integration,
          organization: organization,
          organization_id: organization_id
        )

      attrs = %{provider: :ai}

      {:ok, %Integration{id: ^int_id, provider: :ai, organization_id: ^organization_id}} =
        Integrations.insert_or_update(integration, attrs)
    end
  end
end
