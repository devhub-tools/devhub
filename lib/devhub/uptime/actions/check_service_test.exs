defmodule Devhub.Uptime.Actions.CheckServiceTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime
  alias Devhub.Uptime.Actions.CheckService
  alias DevhubProtos.RequestTracer.V1.TraceResponse

  test "trace_request succeeds" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        expected_status_code: "2xx"
      )

    trace_response =
      %TraceResponse{
        status_code: 200
      }

    expect(Uptime, :trace_request, fn ^service ->
      {:ok, trace_response}
    end)

    assert {:ok, ^trace_response} = CheckService.check_service(service)
  end

  test "trace_request succeeds, but it returns an unexpected code" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        expected_status_code: "2xx"
      )

    trace_response =
      %TraceResponse{
        status_code: 500
      }

    expect(Uptime, :trace_request, fn ^service ->
      {:ok, trace_response}
    end)

    assert {:error, ^trace_response} = CheckService.check_service(service)
  end

  test "trace_request fails" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        expected_status_code: "2xx"
      )

    expect(Uptime, :trace_request, fn ^service ->
      {:error, :timeout}
    end)

    assert {:error, :timeout} = CheckService.check_service(service)
  end
end
