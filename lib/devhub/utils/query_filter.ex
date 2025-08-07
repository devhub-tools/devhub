defmodule Devhub.Utils.QueryFilter do
  @moduledoc false
  import Ecto.Query

  def query_filter(query, filters) do
    Enum.reduce(filters, query, fn filter, query ->
      do_filter(filter, query)
    end)
  end

  defp do_filter({field, {:in, value}}, query) when is_list(value) and value != [] do
    where(query, [table], field(table, ^field) in ^value)
  end

  defp do_filter({_field, {:in, _value}}, query), do: query

  defp do_filter({field, {:like, value}}, query) do
    where(query, [table], ilike(field(table, ^field), ^"%#{value}%"))
  end

  defp do_filter({field, {subfield, value}}, query) when is_list(value) do
    where(query, [table], json_extract_path(field(table, ^field), [^to_string(subfield)]) in ^value)
  end

  defp do_filter({field, value}, query) when is_list(value) do
    where(query, [table], field(table, ^field) in ^value)
  end

  defp do_filter({field, nil}, query) do
    where(query, [table], is_nil(field(table, ^field)))
  end

  defp do_filter({field, {:greater_than, value}}, query) do
    where(query, [table], field(table, ^field) > ^value)
  end

  defp do_filter({field, {:less_than, value}}, query) do
    where(query, [table], field(table, ^field) < ^value)
  end

  defp do_filter({field, value}, query) do
    where(query, [table], field(table, ^field) == ^value)
  end
end
