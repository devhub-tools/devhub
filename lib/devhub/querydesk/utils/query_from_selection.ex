defmodule Devhub.QueryDesk.Utils.QueryFromSelection do
  @moduledoc false

  @spec query_from_selection(String.t(), map()) :: [String.t()]
  def query_from_selection("", _cursor), do: [""]

  def query_from_selection(query, cursor) do
    query |> String.trim() |> do_query_from_selection(parse_cursor(cursor)) |> split_into_queries()
  end

  defp parse_cursor(%{"ranges" => [%{"head" => selection_start, "anchor" => selection_end}]}) do
    {selection_start, selection_end}
  end

  defp parse_cursor(_other) do
    nil
  end

  defp do_query_from_selection(query, {selection_start, selection_end}) when selection_start == selection_end do
    {pre_cursor, post_cursor} = String.split_at(query, selection_start)

    # Replace semicolons in SQL comments to avoid splitting on them
    regex = ~r/--.*?;.*?(\n|$)/

    pre_cursor =
      Regex.replace(regex, pre_cursor, fn match ->
        String.replace(match, ";", "")
      end)

    post_cursor =
      Regex.replace(regex, post_cursor, fn match ->
        String.replace(match, ";", "")
      end)

    at_previous_query_end? = String.ends_with?(pre_cursor, ";") or String.starts_with?(post_cursor, ";")
    next_character_is_whitespace? = String.starts_with?(post_cursor, " ") or String.starts_with?(post_cursor, "\n")
    post_cursor_empty? = String.trim(post_cursor) == ""

    if post_cursor_empty? or (at_previous_query_end? and next_character_is_whitespace?) do
      pre_cursor
      |> String.split(";", trim: true)
      |> Enum.filter(fn line ->
        line = String.trim(line)

        has_non_comment_line? =
          line
          |> String.split("\n")
          |> Enum.any?(fn line ->
            not String.starts_with?(line, "--")
          end)

        line != "" and has_non_comment_line?
      end)
      |> List.last()
      |> String.trim()
    else
      post_cursor_query = post_cursor |> String.split(";", parts: 2) |> Enum.at(0)
      pre_cursor_query = pre_cursor |> String.reverse() |> String.split(";", parts: 2) |> Enum.at(0) |> String.reverse()
      String.trim(pre_cursor_query <> post_cursor_query)
    end
  end

  # query already correctly selected by frontend if start != end
  defp do_query_from_selection(query, _selection) do
    query
  end

  defp split_into_queries(query) do
    query
    |> String.split(";", trim: true)
    |> Enum.map(&String.trim/1)
  end
end
