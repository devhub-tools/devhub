defmodule Devhub.Uptime.Actions.SaveCheckTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Check

  test "success" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)
    Uptime.subscribe_checks()
    Uptime.subscribe_checks(service.id)

    assert %Check{} =
             check =
             Uptime.save_check!(%{
               organization_id: organization.id,
               service_id: service.id,
               status: :timeout,
               time_since_last_check: 10_000
             })

    # should receive two messages for both subscriptions
    assert_receive {Check, ^check}
    assert_receive {Check, ^check}

    Uptime.unsubscribe_checks()
    Uptime.unsubscribe_checks(service.id)
  end
end
