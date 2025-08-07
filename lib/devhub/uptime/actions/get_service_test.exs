defmodule Devhub.Uptime.Actions.GetServiceTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Ecto.Association.NotLoaded

  test "get_service/2" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization_id: organization.id)

    # first check should be excluded by limit
    insert(:uptime_check, service_id: service.id, organization_id: organization.id)
    check = insert(:uptime_check, service_id: service.id, organization_id: organization.id)

    assert {:ok, %{checks: %NotLoaded{}}} = Uptime.get_service(id: service.id)
    assert {:ok, %{checks: %NotLoaded{}}} = Uptime.get_service([id: service.id], preload_checks: false)
    assert {:ok, %{checks: [^check]}} = Uptime.get_service([id: service.id], preload_checks: true, limit_checks: 1)
    assert {:error, :service_not_found} = Uptime.get_service(id: "not-found")
  end
end
