defmodule Devhub.QueryDesk.Actions.CancelQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "cancel_query/2" do
    organization = insert(:organization)
    database = insert(:database, organization: organization)
    credential = insert(:database_credential, database: database)
    query = insert(:query, credential: credential)

    Process.flag(:trap_exit, true)
    task = Task.async(fn -> Process.sleep(10_000) end)

    assert Process.alive?(task.pid)

    assert QueryDesk.cancel_query(query, task)
    refute Process.alive?(task.pid)
  end
end
