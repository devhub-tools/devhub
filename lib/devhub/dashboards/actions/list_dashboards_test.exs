defmodule Devhub.Users.Actions.ListDashboardsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Dashboards

  test "list_dashboards/1" do
    organization = insert(:organization)
    organization_user = insert(:organization_user, organization: organization)
    other_organization_user = insert(:organization_user, organization: organization)

    list = [
      %{id: unrestricted_dashboard_id} =
        insert(:dashboard,
          organization: organization,
          restricted_access: false
        ),
      insert(:dashboard,
        organization: organization,
        restricted_access: true,
        permissions: [
          build(:object_permission,
            organization_user: organization_user,
            permission: :read
          )
        ]
      ),
      insert(:dashboard,
        organization: organization,
        restricted_access: true,
        permissions: [
          build(:object_permission,
            organization_user: organization_user,
            permission: :read
          )
        ]
      ),
      insert(:dashboard,
        organization: organization,
        restricted_access: true,
        permissions: [
          build(:object_permission,
            organization_user: organization_user,
            permission: :read
          )
        ]
      )
    ]

    # Has dashboards
    result = Dashboards.list_dashboards(organization_user)
    result_ids = Enum.map(result, & &1.id)

    assert Enum.all?(list, fn dashboard -> dashboard.id in result_ids end)

    # only can see the dashboard without restricted access
    assert [%{id: ^unrestricted_dashboard_id}] = Dashboards.list_dashboards(other_organization_user)
  end
end
