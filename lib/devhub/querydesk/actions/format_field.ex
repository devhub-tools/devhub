defmodule Devhub.QueryDesk.Actions.FormatField do
  @moduledoc false
  @behaviour __MODULE__

  @doc """
  Returns a three item list for space efficiency to send to the client.

  [formatted_value, type, editable]
  """
  @callback format_field(any()) :: {String.t(), String.t(), boolean()}
  def format_field(field) when is_binary(field) do
    with :error <- if(String.printable?(field), do: {:ok, field}, else: :error),
         :error <- Ecto.UUID.cast(field) do
      ["BINARY (#{byte_size(field)} bytes)", "binary", false]
    else
      {:ok, field} -> [field, "text", true]
    end
  end

  def format_field(%Postgrex.Interval{months: m, days: d, secs: s}) do
    day_seconds = d * 24 * 60 * 60
    total_seconds = day_seconds + s
    days = floor(total_seconds / (24 * 60 * 60))
    hours = floor((total_seconds - days * 24 * 60 * 60) / (60 * 60))
    mins = floor((total_seconds - days * 24 * 60 * 60 - hours * 60 * 60) / 60)

    value =
      case {m, days, hours, mins} do
        {0, 0, 0, mins} -> pluralize_unit(mins, "minute")
        {0, 0, hours, 0} -> pluralize_unit(hours, "hour")
        {0, 0, hours, mins} -> "#{pluralize_unit(hours, "hour")} #{pluralize_unit(mins, "minute")}"
        {0, days, 0, _mins} -> pluralize_unit(days, "day")
        {0, days, hours, _mins} -> "#{pluralize_unit(days, "day")} #{pluralize_unit(hours, "hour")}"
        {months, _days, _hours, _mins} -> pluralize_unit(months, "month")
      end

    [value, "interval", false]
  end

  def format_field(%Postgrex.Range{lower: lower, upper: upper, lower_inclusive: li, upper_inclusive: ui}) do
    [lower_value, _lower_type, _lower_editable] = format_field(lower)
    [upper_value, _upper_type, _upper_editable] = format_field(upper)

    value =
      Enum.join(
        [if(li, do: "[", else: "("), lower_value, ",", upper_value, if(ui, do: "]", else: ")")],
        " "
      )

    [value, "range", false]
  end

  def format_field(%Date{} = field), do: [Date.to_iso8601(field), "date", true]
  def format_field(%DateTime{} = field), do: [DateTime.to_iso8601(field), "datetime", true]

  def format_field(%NaiveDateTime{} = field) do
    value = field |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
    [value, "datetime", true]
  end

  def format_field(%Pgvector{} = field), do: [Pgvector.to_list(field), "list", true]

  def format_field(field) when is_list(field) do
    [Enum.map(field, &(&1 |> format_field() |> hd())), "list", false]
  end

  def format_field(field) when is_tuple(field) do
    field |> Tuple.to_list() |> format_field()
  end

  def format_field(nil), do: ["NULL", "null", true]
  def format_field(%Postgrex.INET{address: address}), do: [address |> :inet.ntoa() |> to_string(), "inet", false]

  def format_field(field) when is_map(field) do
    [field, "json", false]
  end

  def format_field(field) when is_boolean(field), do: [String.upcase("#{field}"), "boolean", true]
  def format_field(field) when is_integer(field), do: [field, "integer", true]
  def format_field(field), do: [to_string(field), "other", true]

  defp pluralize_unit(1, unit), do: "1 #{unit}"
  defp pluralize_unit(units, unit), do: "#{units} #{unit}s"
end
