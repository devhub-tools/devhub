defmodule Devhub.ApiKeysTest do
  use Devhub.DataCase, async: true

  alias Devhub.ApiKeys

  test "api_key flow" do
    %{id: organization_id} = organization = insert(:organization)

    # create/1
    {:ok, %{id: api_key_id}, token} = ApiKeys.create(organization, "test", [:coverbot])

    # verify/1
    assert {:ok,
            %{
              id: ^api_key_id,
              name: "test",
              expires_at: nil,
              organization: %{id: ^organization_id},
              permissions: [:coverbot]
            }} =
             ApiKeys.verify(token)

    # list/1
    assert [%{id: ^api_key_id}] = ApiKeys.list(organization)

    # revoke/1

    assert {:ok, %{id: ^api_key_id}} = ApiKeys.revoke(api_key_id)

    # verify/1

    {:error, :invalid_api_key} = ApiKeys.verify(token)
  end
end
