defmodule Devhub.Coverbot.Actions.LineCovered do
  @moduledoc false
  @behaviour __MODULE__

  @callback line_covered?(map(), integer()) :: boolean() | nil
  def line_covered?(coverage, line_number) do
    coverage
    |> Enum.filter(fn
      {key, _covered} when is_integer(key) -> line_number == key
      {%Range{} = key, _covered} -> line_number in key
    end)
    |> case do
      [] -> nil
      [{_line_number, covered}] -> covered
      multiple -> Enum.all?(multiple, &elem(&1, 1))
    end
  end
end
