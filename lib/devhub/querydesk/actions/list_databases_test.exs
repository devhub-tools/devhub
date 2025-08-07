defmodule Devhub.QueryDesk.Actions.ListDatabasesTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Database

  test "success" do
    organization = insert(:organization)

    organization_user = insert(:organization_user, organization: organization, permissions: %{super_admin: false})
    role = insert(:role, organization: organization)
    insert(:organization_user_role, organization_user: organization_user, role: role)

    _exclude_wrong_org = insert(:database, organization: build(:organization))

    %{id: include_no_restrict} =
      insert(:database, organization: organization, restrict_access: false, name: "a", group: "test")

    _exclude_no_permission = insert(:database, organization: organization, restrict_access: true)

    %{id: include_with_permission} =
      insert(:database,
        organization: organization,
        restrict_access: true,
        permissions: [build(:object_permission, organization_user: organization_user)],
        name: "b",
        group: "test"
      )

    %{id: include_with_role} =
      insert(:database,
        organization: organization,
        restrict_access: true,
        permissions: [build(:object_permission, role: role)],
        name: "c",
        group: "test"
      )

    # no access
    insert(:database,
      organization: organization,
      restrict_access: true,
      name: "d",
      group: "test"
    )

    assert [
             %Database{id: ^include_no_restrict},
             %Database{id: ^include_with_permission},
             %Database{id: ^include_with_role}
           ] = QueryDesk.list_databases(organization_user)

    assert [
             %Database{id: ^include_with_permission},
             %Database{id: ^include_with_role}
           ] = QueryDesk.list_databases(organization_user, filter: [restrict_access: true])
  end
end
