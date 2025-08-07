defmodule Devhub.ApiKeys.Actions.VerifyTest do
  use Devhub.DataCase, async: true

  alias Devhub.ApiKeys

  describe "verify/1" do
    test "valid api_key" do
      organization = insert(:organization)

      {:ok, %{id: api_key_id}, token} = ApiKeys.create(organization, "test", [:coverbot])

      assert {:ok, %{id: ^api_key_id}} = ApiKeys.verify(token)
    end

    test "invalid api_key" do
      assert {:error, :invalid_api_key} = ApiKeys.verify("invalid api_key")
      assert {:error, :invalid_api_key} = ApiKeys.verify("dh_fake_token")
    end
  end
end
