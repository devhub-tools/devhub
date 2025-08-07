defmodule Devhub.Uptime.Actions.ListChecksTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime

  test "success" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    [%{id: check1_id}, %{id: check2_id}, %{id: check3_id}] =
      insert_list(3, :uptime_check, organization: organization, service: service)

    assert [%{id: ^check3_id}, %{id: ^check2_id}] = Uptime.list_checks(service, limit: 2)
    assert [%{id: ^check1_id}] = Uptime.list_checks(service, cursor: {:next, check2_id}, limit: 2)
  end
end
