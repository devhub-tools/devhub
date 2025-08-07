defmodule Devhub.Users.Actions.CreateOrganizationUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Schemas.OrganizationUser

  test "create_organization_user/1" do
    %{id: organization_id} = insert(:organization)

    attrs = %{
      legal_name: "Michael St Clair",
      organization_id: organization_id,
      permissions: %{super_admin: false, manager: false, billing_admin: false}
    }

    assert {:ok, %OrganizationUser{}} =
             Users.create_organization_user(attrs)
  end
end
