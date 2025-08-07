defmodule DevhubProtos.QueryParser.V1.ParseQueryRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :query, 1, type: :string
end

defmodule DevhubProtos.QueryParser.V1.ParseQueryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :json_result, 1, type: :string, json_name: "jsonResult"
end

defmodule DevhubProtos.QueryParser.V1.QueryParserService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "query_parser.v1.QueryParserService",
    protoc_gen_elixir_version: "0.13.0"

  rpc :ParseQuery,
      DevhubProtos.QueryParser.V1.ParseQueryRequest,
      DevhubProtos.QueryParser.V1.ParseQueryResponse
end

defmodule DevhubProtos.QueryParser.V1.QueryParserService.Stub do
  @moduledoc false

  use GRPC.Stub, service: DevhubProtos.QueryParser.V1.QueryParserService.Service
end
