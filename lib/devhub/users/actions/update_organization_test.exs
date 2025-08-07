defmodule Devhub.Users.Actions.UpdateOrganizationTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.Schemas.Organization

  test "update_organization/2" do
    organization = insert(:organization, name: "Devhub")
    attrs = %{name: "Devhub"}

    assert {:ok, %Organization{name: "Devhub"}} = Users.update_organization(organization, attrs)
  end
end
