defmodule Devhub.Users.Actions.GetOidcConfigTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.OIDC

  test "get_oidc_config/1" do
    %{id: organization_id} = insert(:organization)
    %{id: oidc_id} = insert(:oidc, organization_id: organization_id)

    assert {:ok, %OIDC{id: ^oidc_id}, _map} = Users.get_oidc_config(id: oidc_id)
    assert {:error, :oidc_config_not_found} = Users.get_oidc_config(id: "invalid id")
  end
end
