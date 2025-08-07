defmodule Devhub.QueryDesk.Actions.ReplaceQueryVariablesTest do
  use Devhub.DataCase, async: true

  alias Devhub.QueryDesk

  test "replace_query_variables/2" do
    query = "select * from users where id = ${user_id};"

    assert "select * from users where id = 1;" == QueryDesk.replace_query_variables(query, %{"user_id" => 1})
    assert "select * from users where id = ${user_id};" == QueryDesk.replace_query_variables(query, %{})
  end
end
