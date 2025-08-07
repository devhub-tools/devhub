defmodule Devhub.Users.Actions.GetOrganizationUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Schemas.OrganizationUser

  test "get_organization_user/1" do
    %{id: organization_id} = insert(:organization)
    %{id: user_id} = insert(:user, name: "a")
    %{id: org_user_id} = insert(:organization_user, organization_id: organization_id, user_id: user_id)

    assert {:ok, %OrganizationUser{id: ^org_user_id}} = Users.get_organization_user(organization_id: organization_id)
    assert {:error, :organization_user_not_found} = Users.get_organization_user(organization_id: "invalid id")
  end
end
