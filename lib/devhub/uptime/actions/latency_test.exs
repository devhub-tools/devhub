defmodule Devhub.Uptime.Actions.LatencyTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime

  test "success" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)
    insert(:uptime_check, organization: organization, service: service, request_time: 100)

    insert(:uptime_check,
      organization: organization,
      service: service,
      request_time: 110,
      inserted_at: Timex.shift(DateTime.utc_now(), hours: -2)
    )

    insert(:uptime_check_summary,
      service: service,
      avg_request_time: 105,
      date: Date.utc_today()
    )

    insert(:uptime_check_summary,
      service: service,
      avg_request_time: 120,
      date: Date.add(Date.utc_today(), -2)
    )

    insert(:uptime_check_summary,
      service: service,
      avg_request_time: 130,
      date: Date.add(Date.utc_today(), -35)
    )

    assert 100 = Uptime.latency(service.id, "1h")
    assert 105 = Uptime.latency(service.id, "3h")
    assert 105 = Uptime.latency(service.id, "1d")
    assert 113 = Uptime.latency(service.id, "3d")
    assert 113 = Uptime.latency(service.id, "1m")
    assert 118 = Uptime.latency(service.id, "2m")
  end
end
