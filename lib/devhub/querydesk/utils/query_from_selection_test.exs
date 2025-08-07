defmodule Devhub.QueryDesk.Utils.QueryFromSelectionTest do
  use Devhub.DataCase, async: true

  import Devhub.QueryDesk.Utils.QueryFromSelection

  test "query_from_selection/2" do
    query = """
    select * from teams;
    select * from databases;
    select * from users;
    """

    # selection is cursor only
    assert ["select * from databases"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 30, "head" => 30}]})

    # no selection
    assert ["select * from teams", "select * from databases", "select * from users"] == query_from_selection(query, %{})

    # cursor after semicolon with whitespace to right
    assert ["select * from teams"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 20, "head" => 20}]})

    assert ["select * from databases"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 45, "head" => 45}]})

    assert ["select * from users"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 66, "head" => 66}]})

    # cursor at end of query
    assert ["select * from users"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 67, "head" => 67}]})

    query = "select * from users;   "

    assert ["select * from users"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 22, "head" => 22}]})

    query = "select * from agents;\n\n"

    assert ["select * from agents"] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => 20, "head" => 20}]})

    # doesn't break on empty query
    assert [""] == query_from_selection("", %{"ranges" => [%{"anchor" => 0, "head" => 0}]})

    # ignores comments
    query = """
    -- some comment;
    select *
      from organizations;
    -- select * from commits;
    -- select * from users;
    """

    length = String.length(query)

    assert [
             """
             -- some comment
             select *
               from organizations\
             """
           ] ==
             query_from_selection(query, %{"ranges" => [%{"anchor" => length, "head" => length}]})
  end
end
