defmodule Devhub.Uptime.Actions.UptimePercentageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime

  test "success" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    insert(:uptime_check, organization: organization, service: service, status: :success)

    insert(:uptime_check,
      organization: organization,
      service: service,
      status: :failure,
      inserted_at: Timex.shift(DateTime.utc_now(), hours: -2)
    )

    insert(:uptime_check_summary,
      service: service,
      success_percentage: Decimal.new("0.5"),
      date: Date.utc_today()
    )

    insert(:uptime_check_summary,
      service: service,
      success_percentage: Decimal.new("0.4"),
      date: Date.add(Date.utc_today(), -2)
    )

    insert(:uptime_check_summary,
      service: service,
      success_percentage: Decimal.new("0.3"),
      date: Date.add(Date.utc_today(), -35)
    )

    assert 1.0 = Uptime.uptime_percentage(service.id, "1h")
    assert 0.5 = Uptime.uptime_percentage(service.id, "3h")
    assert 0.5 = Uptime.uptime_percentage(service.id, "1d")
    assert 0.45 = Uptime.uptime_percentage(service.id, "3d")
    assert 0.45 = Uptime.uptime_percentage(service.id, "1m")
    assert 0.4 = Uptime.uptime_percentage(service.id, "3m")
  end

  test "works when no checks" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    assert +0.0 = Uptime.uptime_percentage(service.id, "1h")
    assert +0.0 = Uptime.uptime_percentage(service.id, "1d")
  end
end
