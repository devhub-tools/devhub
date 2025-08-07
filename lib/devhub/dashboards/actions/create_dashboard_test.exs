defmodule Devhub.Users.Actions.CreateDashboardTest do
  use Devhub.DataCase, async: true

  alias Devhub.Dashboards
  alias Devhub.Dashboards.Schemas.Dashboard

  test "create_dashboard/1" do
    %{id: organization_id} = organization = insert(:organization)
    name = "Rita's Repulsive Dashboard"

    # Create a dashboard
    assert {:ok, %Dashboard{}} =
             Dashboards.create_dashboard(%{name: name, organization_id: organization.id, restricted_access: false})

    # Dashboards names are unique per organization
    assert {:error,
            %Ecto.Changeset{
              errors: [
                name:
                  {"has already been taken",
                   [
                     constraint: :unique,
                     constraint_name: "dashboards_organization_id_name_index"
                   ]}
              ]
            }} = Dashboards.create_dashboard(%{name: name, organization_id: organization.id, restricted_access: false})

    # Dashboard names may be reused when dashboard is archived
    now = DateTime.utc_now()

    Repo.update_all(
      from(d in Dashboard, where: d.organization_id == ^organization_id, update: [set: [archived_at: ^now]]),
      []
    )

    assert {:ok, %Dashboard{}} =
             Dashboards.create_dashboard(%{name: name, organization_id: organization.id, restricted_access: false})
  end
end
