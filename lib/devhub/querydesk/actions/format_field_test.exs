defmodule Devhub.QueryDesk.Actions.FormatFieldTest do
  use ExUnit.Case

  test "uuid" do
    uuid = Ecto.UUID.generate()
    {:ok, uuid_binary} = Ecto.UUID.dump(uuid)

    assert Devhub.QueryDesk.format_field(uuid_binary) == ["#{uuid}", "text", true]
  end

  test "date" do
    date = Date.utc_today()
    date_iso8601 = Date.to_iso8601(date)

    assert Devhub.QueryDesk.format_field(date) == [date_iso8601, "date", true]
  end

  test "datetime" do
    datetime = DateTime.utc_now()
    datetime_iso8601 = DateTime.to_iso8601(datetime)

    assert Devhub.QueryDesk.format_field(datetime) == [datetime_iso8601, "datetime", true]
  end

  test "naive_datetime" do
    naive_datetime = NaiveDateTime.utc_now()

    naive_datetime_iso8601 =
      naive_datetime
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_iso8601()

    assert Devhub.QueryDesk.format_field(naive_datetime) == [naive_datetime_iso8601, "datetime", true]
  end

  test "range" do
    range = %Postgrex.Range{
      lower: 1,
      upper: 3,
      lower_inclusive: false,
      upper_inclusive: true
    }

    assert Devhub.QueryDesk.format_field(range) == ["( 1 , 3 ]", "range", false]
  end

  test "interval" do
    Enum.each(
      [
        {%Postgrex.Interval{months: 0, days: 0, secs: 60}, "1 minute"},
        {%Postgrex.Interval{months: 0, days: 1, secs: 0}, "1 day"},
        {%Postgrex.Interval{months: 1, days: 0, secs: 0}, "1 month"},
        {%Postgrex.Interval{months: 0, days: 0, secs: 4 * 60 * 60}, "4 hours"},
        {%Postgrex.Interval{months: 0, days: 0, secs: 2 * 60 * 60 + 60}, "2 hours 1 minute"},
        {%Postgrex.Interval{months: 0, days: 1, secs: 2 * 60 * 60}, "1 day 2 hours"}
      ],
      fn {interval, expected} ->
        assert Devhub.QueryDesk.format_field(interval) == [expected, "interval", false]
      end
    )
  end

  test "inet" do
    inet = %Postgrex.INET{address: {127, 0, 0, 1}}

    assert Devhub.QueryDesk.format_field(inet) == ["127.0.0.1", "inet", false]
  end

  test "binary" do
    binary = <<0, :crypto.strong_rand_bytes(7)::binary>>

    assert Devhub.QueryDesk.format_field(binary) == ["BINARY (8 bytes)", "binary", false]
  end

  test "nil" do
    assert Devhub.QueryDesk.format_field(nil) == ["NULL", "null", true]
  end

  test "json" do
    map = %{test: "test"}

    assert Devhub.QueryDesk.format_field(map) == [%{test: "test"}, "json", false]
  end

  test "boolean" do
    assert Devhub.QueryDesk.format_field(true) == ["TRUE", "boolean", true]
    assert Devhub.QueryDesk.format_field(false) == ["FALSE", "boolean", true]
  end

  test "list" do
    list = ["item-1", "item-2"]

    assert Devhub.QueryDesk.format_field(list) == [["item-1", "item-2"], "list", false]

    list = [%{"item" => 1}, %{"item" => 2}]

    assert Devhub.QueryDesk.format_field(list) == [[%{"item" => 1}, %{"item" => 2}], "list", false]
  end
end
