defmodule Devhub.Uptime.CheckJobTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Devhub.Uptime.RequestTracerService
  alias Devhub.Uptime.Schemas.Service
  alias DevhubProtos.RequestTracer.V1.Header
  alias DevhubProtos.RequestTracer.V1.TraceResponse

  test "success" do
    organization = insert(:organization)

    %{name: name, organization_id: organization_id, enabled: enabled} =
      service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        request_headers: [%{key: "x-request-id", value: "123"}]
      )

    expect(Uptime, :trace_request, fn %Service{
                                        name: ^name,
                                        organization_id: ^organization_id,
                                        enabled: ^enabled
                                      } ->
      {:ok,
       %TraceResponse{status_code: 200, complete: 100, response_headers: [%Header{key: "x-request-id", value: "123"}]}}
    end)

    assert :ok = Uptime.CheckJob.perform(%Oban.Job{args: %{"id" => service.id}, scheduled_at: DateTime.utc_now()})

    assert [%{status: :success, request_time: 100, response_headers: [%{key: "x-request-id", value: "123"}]}] =
             Uptime.list_checks(service, page: 1)
  end

  test "handles timeout" do
    organization = insert(:organization)

    %{name: name, organization_id: organization_id, enabled: enabled} =
      service = insert(:uptime_service, organization: organization, enabled: true)

    genserver = Process.whereis(RequestTracerService)

    expect(Uptime, :trace_request, fn %Service{
                                        name: ^name,
                                        organization_id: ^organization_id,
                                        enabled: ^enabled
                                      } ->
      {:error, :timeout}
    end)

    allow(Stub, self(), genserver)

    assert :ok = Uptime.CheckJob.perform(%Oban.Job{args: %{"id" => service.id}, scheduled_at: DateTime.utc_now()})
    assert [%{status: :timeout}] = Uptime.list_checks(service, page: 1)
  end
end
