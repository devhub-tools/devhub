defmodule Devhub.ApiKeys.Actions.RevokeTest do
  use Devhub.DataCase, async: true

  alias Devhub.ApiKeys
  alias Devhub.ApiKeys.Schemas.ApiKey

  describe "revoke/1" do
    test "sucessfully revoke api key" do
      organization = %{id: organization_id} = insert(:organization)

      %{id: api_key_id} =
        insert(:api_key,
          expires_at: ~U[2025-01-01 12:00:00Z],
          organization_id: organization_id,
          organization: organization
        )

      assert {:ok, %ApiKey{}} = ApiKeys.revoke(api_key_id)
    end

    test "api key not found" do
      {:error, :api_key_not_found} = ApiKeys.revoke("invalid api key")
    end
  end
end
