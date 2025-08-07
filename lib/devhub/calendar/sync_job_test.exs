defmodule Devhub.Calendar.SyncJobTest do
  use Devhub.DataCase, async: true

  test "perform/1" do
    organization = insert(:organization)
    insert(:ical, organization: organization, link: "webcal://api.rippling.com")

    expect(Devhub.Calendar, :sync, fn _ical -> :ok end)

    assert :ok = Devhub.Calendar.SyncJob.perform(%{})
  end
end
