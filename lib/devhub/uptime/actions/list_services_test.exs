defmodule Devhub.Uptime.Actions.ListServicesTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Ecto.Association.NotLoaded

  test "success" do
    organization = insert(:organization)
    %{id: service_id} = insert(:uptime_service, organization: organization)

    assert [%{id: ^service_id, checks: %NotLoaded{}}] = Uptime.list_services(organization.id)
    assert [%{id: ^service_id, checks: []}] = Uptime.list_services(organization.id, preload_checks: true)
  end
end
