defmodule Devhub.Workflows.Actions.ReplaceVariables do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Workflows.Schemas.Run

  @callback replace_variables(map(), String.t(), [Run.Step.t()]) :: String.t()
  def replace_variables(input, string, steps) do
    input = Map.put(input, :timestamp, DateTime.to_unix(DateTime.utc_now()))

    # replace step outputs
    string =
      ~r/\${step\.([a-z0-9\-]+)\.output\.([^}]+)}/
      |> Regex.scan(string)
      |> Enum.reduce(string, fn [ref, step_name, access], acc ->
        output =
          case Enum.find(steps, &(&1.name == step_name)) do
            %{output: output} -> get_in_output(output, String.split(access, [".", "[", "]"], trim: true))
            _error -> ref <> " (step lookup failed)"
          end

        String.replace(acc, ref, to_string(output))
      end)

    # replace variables
    Enum.reduce(input, string, fn {key, value}, acc ->
      String.replace(acc, "${#{key}}", to_string(value))
    end)
  end

  defp get_in_output(output, []), do: output

  defp get_in_output(output, [head | path]) do
    output =
      if is_list(output) do
        output |> Enum.with_index() |> Map.new(fn {item, index} -> {to_string(index), item} end)
      else
        output
      end

    output |> get_in([head]) |> get_in_output(path)
  end
end
