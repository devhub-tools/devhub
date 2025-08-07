defmodule Devhub.Workflows.Schemas.Step.QueryActionTest do
  use Devhub.DataCase, async: true

  alias Devhub.Workflows.Schemas.Step.QueryAction

  test "format_result/1" do
    uuid = Ecto.UUID.generate()

    result = %Postgrex.Result{
      columns: ["id", "uuid", "binary"],
      command: :SELECT,
      messages: [],
      num_rows: 1,
      rows: [[1, "1", uuid, <<1, 2, 3>>]]
    }

    assert QueryAction.format_result(result) == %{
             "columns" => ["id", "uuid", "binary"],
             "command" => :SELECT,
             "connection_id" => nil,
             "messages" => [],
             "num_rows" => 1,
             "rows" => [[1, "1", uuid, "BINARY (3 bytes)"]]
           }
  end
end
