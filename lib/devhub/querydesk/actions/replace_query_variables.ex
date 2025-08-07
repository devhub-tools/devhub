defmodule Devhub.QueryDesk.Actions.ReplaceQueryVariables do
  @moduledoc false

  @behaviour __MODULE__

  @callback replace_query_variables(String.t() | [String.t()], map()) :: String.t() | [String.t()]
  def replace_query_variables(queries, variables) when is_list(queries) do
    Enum.map(queries, fn query -> replace_query_variables(query, variables) end)
  end

  def replace_query_variables(query, variables) do
    Enum.reduce(variables, query, fn {key, value}, acc ->
      String.replace(acc, "${#{key}}", to_string(value))
    end)
  end
end
