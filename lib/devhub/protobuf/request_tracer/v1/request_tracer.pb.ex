defmodule DevhubProtos.RequestTracer.V1.Header do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule DevhubProtos.RequestTracer.V1.TraceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :url, 1, type: :string
  field :method, 2, type: :string
  field :request_body, 3, type: :string, json_name: "requestBody"

  field :request_headers, 4,
    repeated: true,
    type: DevhubProtos.RequestTracer.V1.Header,
    json_name: "requestHeaders"
end

defmodule DevhubProtos.RequestTracer.V1.TraceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :dns_done, 1, type: :int32, json_name: "dnsDone"
  field :connect_done, 2, type: :int32, json_name: "connectDone"
  field :tls_done, 3, type: :int32, json_name: "tlsDone"
  field :first_byte_received, 4, type: :int32, json_name: "firstByteReceived"
  field :complete, 5, type: :int32
  field :status_code, 6, type: :int32, json_name: "statusCode"
  field :response_body, 7, type: :string, json_name: "responseBody"

  field :response_headers, 8,
    repeated: true,
    type: DevhubProtos.RequestTracer.V1.Header,
    json_name: "responseHeaders"
end

defmodule DevhubProtos.RequestTracer.V1.RequestTracerService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "request_tracer.v1.RequestTracerService",
    protoc_gen_elixir_version: "0.13.0"

  rpc :Trace,
      DevhubProtos.RequestTracer.V1.TraceRequest,
      DevhubProtos.RequestTracer.V1.TraceResponse
end

defmodule DevhubProtos.RequestTracer.V1.RequestTracerService.Stub do
  @moduledoc false

  use GRPC.Stub, service: DevhubProtos.RequestTracer.V1.RequestTracerService.Service
end
