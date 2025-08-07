defmodule Devhub.Users.Actions.UpdateOrganizationUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Schemas.OrganizationUser

  test "update_organization_user/2" do
    %{id: organization_id} = insert(:organization)
    organization_user = insert(:organization_user, organization_id: organization_id, legal_name: "Brianna St Claire")
    attrs = %{legal_name: "Brianna St Clair"}

    assert {:ok, %OrganizationUser{legal_name: "Brianna St Clair"}} =
             Users.update_organization_user(organization_user, attrs)
  end
end
