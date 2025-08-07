defmodule Devhub.Users.Actions.GetOrganizationTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Schemas.Organization

  test "get_organization/0" do
    installation_id = UXID.generate!(prefix: "it")

    expect(Tesla.Adapter.Finch, :call, fn %Tesla.Env{
                                            method: :post,
                                            url: "https://licensing.devhub.cloud/installations",
                                            body: body,
                                            headers: [
                                              {"traceparent", _traceparent},
                                              {"content-type", "application/json"}
                                            ]
                                          },
                                          _opts ->
      assert %{
               "organization_id" => _organization_id,
               "app_url" => "http://localhost:4002",
               "public_key" => _public_key,
               "installed_version" => "empty"
             } = Jason.decode!(body)

      TeslaHelper.response(body: %{"installation_id" => installation_id})
    end)

    # create organization if none exist
    assert %Organization{id: id, installation_id: ^installation_id} = Users.get_organization()

    assert %Organization{id: ^id, installation_id: ^installation_id} = Users.get_organization()

    insert(:organization)

    assert_raise RuntimeError, "Multiple organizations not currently supported", fn ->
      Users.get_organization()
    end
  end

  test "get_organization/1" do
    %{id: org_id, installation_id: installation_id} = insert(:organization)

    assert {:ok, %Organization{id: ^org_id}} = Users.get_organization(id: org_id)
    assert {:ok, %Organization{id: ^org_id}} = Users.get_organization(installation_id: installation_id)
    assert {:error, :organization_not_found} = Users.get_organization(id: "idontexist")
  end
end
