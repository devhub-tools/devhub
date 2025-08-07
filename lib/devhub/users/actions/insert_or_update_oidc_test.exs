defmodule Devhub.Users.Actions.InsertOrUpdateOidcTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.OIDC

  test "insert_or_update_oidc/1" do
    %{id: organization_id} = insert(:organization)
    oidc = %OIDC{}
    client_id = Ecto.UUID.generate()

    attrs = %{
      organization_id: organization_id,
      discovery_document_uri: Ecto.UUID.generate(),
      client_id: client_id,
      client_secret: "secret"
    }

    # insert
    assert {:ok, %OIDC{id: id, client_id: ^client_id, client_secret: "secret"} = oidc} =
             Users.insert_or_update_oidc(oidc, attrs)

    # update
    assert {:ok, %OIDC{id: ^id, client_id: ^client_id, client_secret: "new_secret"}} =
             Users.insert_or_update_oidc(oidc, %{client_secret: "new_secret"})
  end
end
