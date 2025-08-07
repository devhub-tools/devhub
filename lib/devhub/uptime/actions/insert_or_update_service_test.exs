defmodule Devhub.Uptime.Actions.InsertOrUpdateServiceTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Devhub.Uptime.Schemas.Service

  test "can update" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    assert {:ok, service} = Uptime.insert_or_update_service(service, %{name: "Devhub"})

    assert_enqueued worker: Uptime.CheckJob, args: %{id: service.id}
  end

  test "enforces minimum interval on cloud hosted" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    assert {:ok, %{interval_ms: 20_000}} =
             Uptime.insert_or_update_service(service, %{name: "self hosted", interval_ms: 20_000})

    expect(Devhub, :cloud_hosted?, fn -> true end)

    assert {:error,
            %Ecto.Changeset{
              errors: [
                interval_ms: {"must be at least 60 seconds", [validation: :number, kind: :greater_than, number: 60_000]}
              ]
            }} =
             Uptime.insert_or_update_service(service, %{name: "cloud hosted", interval_ms: 20_000})
  end

  test "returns validation errors on update" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    assert {
             :error,
             %Ecto.Changeset{
               errors: [
                 name: {"can't be blank", [validation: :required]},
                 url: {"can't be blank", [validation: :required]}
               ]
             }
           } =
             Uptime.insert_or_update_service(service, %{
               name: "",
               url: ""
             })

    refute_enqueued worker: Uptime.CheckJob
  end

  test "can create" do
    organization = insert(:organization)

    assert {:ok, service} =
             Uptime.insert_or_update_service(%Service{}, %{
               organization_id: organization.id,
               name: "Devhub",
               url: "https://app.devhub.cloud/_health"
             })

    assert_enqueued worker: Uptime.CheckJob, args: %{id: service.id}
  end

  test "returns validation errors on create" do
    organization = insert(:organization)

    assert {
             :error,
             %Ecto.Changeset{
               errors: [
                 name: {"can't be blank", [validation: :required]},
                 url: {"can't be blank", [validation: :required]}
               ]
             }
           } =
             Uptime.insert_or_update_service(%Service{}, %{
               organization_id: organization.id
             })

    refute_enqueued worker: Uptime.CheckJob
  end
end
