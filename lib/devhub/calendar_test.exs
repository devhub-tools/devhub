defmodule Devhub.CalendarTest do
  use Devhub.DataCase, async: true

  alias Devhub.Calendar
  alias Devhub.Calendar.Storage

  test "get_events/3" do
    organization = build(:organization)
    linear_user = build(:linear_user, organization_id: organization.id)

    event =
      build(:event,
        title: "OOO",
        color: "red",
        organization_id: organization.id,
        linear_user: linear_user,
        linear_user_id: linear_user.id,
        start_date: ~D[2024-01-01],
        end_date: ~D[2024-01-02]
      )

    expect(Storage, :get_events, fn ^organization, _start_date, _end_date -> [event] end)

    assert [event] ==
             Calendar.get_events(organization, ~D[2023-12-29], ~D[2024-01-03])
  end

  test "create_event/1" do
    %{id: organization_id} = build(:organization)
    %{id: linear_user_id} = build(:linear_user, organization_id: organization_id)

    params = %{
      title: "OOO",
      color: "black",
      start_date: ~D[2024-01-01],
      end_date: ~D[2024-01-03],
      organization_id: organization_id,
      linear_user_id: linear_user_id
    }

    event = build(:event, params)

    expect(Storage, :create_event, fn ^params -> {:ok, event} end)
    assert {:ok, event} == Calendar.create_event(params)
  end

  test "sync/1" do
    %{id: organization_id} = build(:organization)

    integration =
      build(:ical,
        link: "webcal://api.rippling.com",
        organization_id: organization_id
      )

    event_one_uid = Ecto.UUID.generate()
    event_two_uid = Ecto.UUID.generate()

    expect(Tesla.Adapter.Finch, :call, fn %Tesla.Env{method: :get, url: "https://api.rippling.com"}, _opts ->
      TeslaHelper.response(
        body: """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Rippling Inc//Cal//
        CALSCALE:GREGORIAN
        METHOD:publish
        REFRESH-INTERVAL:PT1H
        X-PUBLISHED-TTL:PT1H
        X-WR-CALNAME:PTO calendar of my all reports
        X-WR-TIMEZONE:UTC
        BEGIN:VEVENT
        SUMMARY:Michael St Clair is Out of Office
        DTSTART;VALUE=DATE:20240715
        DTEND;VALUE=DATE:20240716
        DTSTAMP;VALUE=DATE-TIME:20240808T005149Z
        UID:#{event_one_uid}
        DESCRIPTION:
        END:VEVENT
        BEGIN:VEVENT
        SUMMARY:Michael St Clair is Out of Office
        DTSTART;VALUE=DATE:20240718
        DTEND;VALUE=DATE:20240719
        DTSTAMP;VALUE=DATE-TIME:20240808T005149Z
        UID:#{event_two_uid}
        DESCRIPTION:
        END:VEVENT
        END:VCALENDAR
        """
      )
    end)

    expect(Storage, :insert_events, fn [
                                         %{
                                           title: "OOO",
                                           color: "red",
                                           organization_id: ^organization_id,
                                           start_date: ~D[2024-07-18],
                                           end_date: ~D[2024-07-19],
                                           external_id: ^event_two_uid,
                                           person: "Michael St Clair"
                                         } = event_two,
                                         %{
                                           title: "OOO",
                                           color: "red",
                                           organization_id: ^organization_id,
                                           start_date: ~D[2024-07-15],
                                           end_date: ~D[2024-07-16],
                                           external_id: ^event_one_uid,
                                           person: "Michael St Clair"
                                         } = event_one
                                       ] ->
      {2, [build(:event, event_two), build(:event, event_one)]}
    end)

    assert :ok = Calendar.sync(integration)
  end

  test "count_business_days/2" do
    start_date = ~D[2024-01-01]
    end_date = ~D[2024-01-31]

    assert 19 = Calendar.count_business_days(start_date, end_date)
  end
end
