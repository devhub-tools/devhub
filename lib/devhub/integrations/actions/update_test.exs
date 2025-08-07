defmodule Devhub.Integrations.Actions.UpdateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations
  alias Devhub.Integrations.Schemas.Integration

  describe "update/2" do
    test "sucessfully update integration" do
      %{id: organization_id} = organization = insert(:organization)

      integration =
        insert(:integration,
          provider: :github,
          organization_id: organization_id,
          organization: organization
        )

      params = %{
        provider: :linear
      }

      assert {:ok, %Integration{provider: :linear}} = Integrations.update(integration, params)
    end
  end
end
