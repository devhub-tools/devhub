defmodule Devhub.Calendar.Deserialize do
  @moduledoc """
  Deserialize ICalendar Strings into Event structs.
  """

  defmodule Property do
    @moduledoc """
    Provide structure to define properties of an Event.
    """

    defstruct key: nil,
              value: nil,
              params: %{}
  end

  def from_ics(ics) do
    ics
    |> String.trim()
    # deal with Google Calendar's wrapping
    |> String.replace(~r/\r?\n[ \t]/, "")
    |> String.split("\n")
    |> Enum.map(&(&1 |> String.trim_trailing() |> String.replace(~S"\n", "\n")))
    |> get_events()
  end

  def get_events(calendar_data, event_collector \\ [], temp_collector \\ [])

  def get_events([head | calendar_data], event_collector, temp_collector) do
    case head do
      "BEGIN:VEVENT" ->
        # start collecting event
        get_events(calendar_data, event_collector, [head])

      "END:VEVENT" ->
        # finish collecting event
        event = build_event([head | temp_collector])
        get_events(calendar_data, [event | event_collector], [])

      event_property when temp_collector != [] ->
        get_events(calendar_data, event_collector, [event_property | temp_collector])

      _unimportant_stuff ->
        get_events(calendar_data, event_collector, temp_collector)
    end
  end

  def get_events([], event_collector, _temp_collector), do: event_collector

  defp build_event(lines) when is_list(lines) do
    lines
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(&retrieve_kvs/1)
    |> Enum.reduce(%{}, &parse_attr/2)
  end

  defp retrieve_kvs(line) do
    # Split Line up into key and value
    {key, value, params} =
      case String.split(line, ":", parts: 2, trim: true) do
        [key, value] ->
          [key, params] = retrieve_params(key)
          {key, value, params}

        [key] ->
          {key, nil, %{}}
      end

    %Property{key: String.upcase(key), value: value, params: params}
  end

  defp retrieve_params(key) do
    [key | params] = String.split(key, ";", trim: true)

    params =
      Enum.reduce(params, %{}, fn param, acc ->
        case String.split(param, "=", parts: 2, trim: true) do
          [key, val] -> Map.put(acc, key, val)
          [key] -> Map.put(acc, key, nil)
          _other -> acc
        end
      end)

    [key, params]
  end

  defp parse_attr(%Property{key: _key, value: nil}, acc), do: acc

  defp parse_attr(%Property{key: "DTSTART", value: dtstart, params: params}, acc) do
    {:ok, timestamp} = to_date(dtstart, params)
    Map.put(acc, :start_date, DateTime.to_date(timestamp))
  end

  defp parse_attr(%Property{key: "DTEND", value: dtend, params: params}, acc) do
    {:ok, timestamp} = to_date(dtend, params)
    Map.put(acc, :end_date, DateTime.to_date(timestamp))
  end

  defp parse_attr(%Property{key: "SUMMARY", value: summary}, acc) do
    person = summary |> String.replace(~s(\\), "") |> String.replace(" is Out of Office", "")
    Map.put(acc, :person, person)
  end

  defp parse_attr(%Property{key: "UID", value: uid}, acc) do
    Map.put(acc, :external_id, uid)
  end

  defp parse_attr(_property, acc), do: acc

  defp to_date(date_string, %{"TZID" => timezone}) do
    # Microsoft Outlook calendar .ICS files report times in Greenwich Standard Time (UTC +0)
    # so just convert this to UTC
    timezone =
      if Regex.match?(~r/\//, timezone) do
        timezone
      else
        Timex.Timezone.Utils.to_olson(timezone)
      end

    date_string =
      case String.last(date_string) do
        "Z" -> date_string
        _last -> date_string <> "Z"
      end

    Timex.parse(date_string <> timezone, "{YYYY}{0M}{0D}T{h24}{m}{s}Z{Zname}")
  end

  defp to_date(date_string, %{"VALUE" => "DATE"}) do
    to_date(date_string <> "T000000Z")
  end

  defp to_date(date_string, %{}) do
    to_date(date_string, %{"TZID" => "Etc/UTC"})
  end

  defp to_date(date_string) do
    to_date(date_string, %{"TZID" => "Etc/UTC"})
  end
end
