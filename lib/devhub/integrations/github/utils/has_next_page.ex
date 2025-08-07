defmodule Devhub.Integrations.GitHub.Utils.HasNextPage do
  @moduledoc false

  @spec has_next_page?(boolean(), Date.t(), String.t()) :: boolean()
  def has_next_page?(has_next_page, since, data_through) do
    cond do
      not has_next_page ->
        false

      is_nil(since) ->
        has_next_page

      true ->
        {:ok, data_through, 0} = DateTime.from_iso8601(data_through)
        Date.before?(since, data_through)
    end
  end
end
