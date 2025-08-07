defmodule Devhub.Calendar.StorageTest do
  use Devhub.DataCase, async: true

  alias Devhub.Calendar.Storage

  test "get_events/3" do
    organization = insert(:organization)
    %{id: user_id} = linear_user = insert(:linear_user, organization: organization)

    %{id: event_1_id} =
      insert(:event,
        organization_id: organization.id,
        linear_user: linear_user,
        linear_user_id: user_id,
        start_date: ~D[2024-01-01],
        end_date: ~D[2024-01-02]
      )

    %{id: event_2_id} =
      insert(:event,
        organization_id: organization.id,
        linear_user: linear_user,
        linear_user_id: user_id,
        external_id: "12345",
        start_date: ~D[2024-01-02],
        end_date: ~D[2024-01-02]
      )

    # should be excluded by date filter
    insert(:event,
      organization_id: organization.id,
      linear_user: linear_user,
      linear_user_id: user_id,
      external_id: "2314",
      start_date: ~D[2023-01-03],
      end_date: ~D[2023-01-03]
    )

    assert [%{id: ^event_1_id}, %{id: ^event_2_id}] =
             organization
             |> Storage.get_events(~D[2024-01-01], ~D[2024-01-02])
             |> Enum.sort_by(& &1.start_date, Date)
  end

  test "create_event/1" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: linear_user_id} = insert(:linear_user, organization: organization)

    event_params = %{
      organization_id: organization_id,
      linear_user_id: linear_user_id,
      title: "000",
      color: "red"
    }

    assert {:ok, _event} = Storage.create_event(event_params)
  end

  test "insert_events/1" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: linear_user_id} = insert(:linear_user, organization: organization)

    events = [
      %{
        id: "bcd4",
        organization_id: organization_id,
        linear_user_id: linear_user_id,
        title: "000",
        color: "red"
      },
      %{
        id: "a2dc",
        organization_id: organization_id,
        linear_user_id: linear_user_id,
        title: "000",
        color: "red"
      }
    ]

    assert {2, _data} = Storage.insert_events(events)
  end
end
