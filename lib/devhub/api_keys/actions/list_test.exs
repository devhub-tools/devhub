defmodule Devhub.ApiKeys.Actions.ListTest do
  use Devhub.DataCase, async: true

  alias Devhub.ApiKeys
  alias Devhub.ApiKeys.Schemas.ApiKey

  test "list/1" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: organization_id_2} = organization_2 = insert(:organization)
    insert(:api_key, exprires_at: nil, organization: organization, organization_id: organization_id)
    insert(:api_key, exprires_at: nil, organization: organization_2, organization_id: organization_id_2)

    assert [%ApiKey{}] = ApiKeys.list(organization)
  end
end
