defmodule Devhub.Utils.WithSpan do
  @moduledoc false
  use Decorator.Define, with_span: 0

  def with_span(body, context) do
    name = default_name(context)
    OpenTelemetryDecorator.with_span(name, body, context)
  end

  defp default_name(%{module: module, name: function, arity: arity}) do
    module =
      module
      |> Atom.to_string()
      |> String.trim_leading("Elixir.")

    "#{module}.#{function}/#{arity}"
  end
end
