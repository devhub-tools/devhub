defmodule Devhub.Coverbot.Actions.ParseFileCoverage do
  @moduledoc false
  @behaviour __MODULE__

  @callback parse_file_coverage(map()) :: map()
  def parse_file_coverage(coverage) do
    Map.new(coverage || [], fn {line_number, covered} ->
      key =
        case String.split(line_number, ",") do
          [line_number] ->
            String.to_integer(line_number)

          [start_number, end_number] ->
            {start_number, _rest} = Integer.parse(start_number)
            {end_number, _rest} = Integer.parse(end_number)
            start_number..end_number
        end

      {key, covered}
    end)
  end
end
