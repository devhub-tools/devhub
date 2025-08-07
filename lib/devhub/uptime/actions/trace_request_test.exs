defmodule Devhub.Uptime.Actions.TraceRequestTest do
  use Devhub.DataCase, async: false

  alias Devhub.Uptime
  alias DevhubProtos.RequestTracer.V1.Header
  alias DevhubProtos.RequestTracer.V1.RequestTracerService.Stub
  alias DevhubProtos.RequestTracer.V1.TraceRequest
  alias DevhubProtos.RequestTracer.V1.TraceResponse

  setup :set_mimic_global

  test "success" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        request_headers: [%{key: "x-request-id", value: "123"}]
      )

    trace_response =
      %TraceResponse{
        status_code: 200,
        complete: 100,
        response_headers: [%Header{key: "x-request-id", value: "123"}]
      }

    expect(Stub, :trace, fn _channel, %TraceRequest{} ->
      {:ok, trace_response}
    end)

    assert {:ok, ^trace_response} = Uptime.trace_request(service)
  end

  test "generic TraceResponse error returns itself" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        request_headers: [%{key: "x-request-id", value: "123"}],
        timeout_ms: 5
      )

    expect(Stub, :trace, fn _channel, %TraceRequest{} ->
      {:error, :generic_error}
    end)

    assert {:error, :generic_error} = Uptime.trace_request(service)
  end

  test "timeout" do
    organization = insert(:organization)

    service =
      insert(:uptime_service,
        organization: organization,
        enabled: true,
        request_headers: [%{key: "x-request-id", value: "123"}],
        timeout_ms: 5
      )

    trace_response =
      %TraceResponse{
        status_code: 200,
        complete: 100,
        response_headers: [%Header{key: "x-request-id", value: "123"}]
      }

    expect(Stub, :trace, fn _channel, %TraceRequest{} ->
      :timer.sleep(10)
      {:ok, trace_response}
    end)

    assert {:error, :timeout} = Uptime.trace_request(service)
  end
end
