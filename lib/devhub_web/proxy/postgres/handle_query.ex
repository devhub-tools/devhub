defmodule DevhubWeb.Proxy.Postgres.HandleQuery do
  @moduledoc false

  import DevhubWeb.Proxy.Postgres.SendToDatabase

  alias Devhub.QueryDesk
  alias DevhubWeb.Proxy.Postgres.ClientState

  require Logger

  def handle_query(query, %ClientState{} = state, msg_type, rest \\ nil) do
    if database_select_query?(query) do
      Logger.debug("running database select query: #{query}")
      handle_database_select_query(state)
    else
      Logger.debug("running query: #{query}")
      log_and_run_query(query, state, msg_type, rest)
    end
  end

  defp log_and_run_query(
         query_string,
         %ClientState{database: database, organization_user: organization_user} = state,
         msg_type,
         rest
       ) do
    {:ok, query} =
      QueryDesk.create_query(%{
        organization_id: database.organization_id,
        credential_id: database.default_credential.id,
        query: query_string,
        executed_at: DateTime.utc_now(),
        failed: false,
        user_id: organization_user.user_id
      })

    msg =
      query
      |> QueryDesk.preload_query_for_run()
      |> protect_query()
      |> encode_query_msg(msg_type, rest)

    :ok = send_to_database(state, msg)
  end

  if Code.ensure_loaded?(Devhub.DataProtection) do
    defdelegate protect_query(query), to: Devhub.DataProtection
  else
    defp protect_query(query), do: {:ok, query.query}
  end

  defp database_select_query?("SELECT d.datname" <> _rest), do: true
  defp database_select_query?("SELECT datName" <> _rest), do: true
  defp database_select_query?("SELECT datname" <> _rest), do: true
  defp database_select_query?(_query), do: false

  defp handle_database_select_query(%ClientState{conn: conn, organization_user: organization_user}) do
    tables = organization_user |> QueryDesk.list_databases(filter: [adapter: :postgres]) |> Enum.map(&[&1.name])

    row_desc = encode_row_description_msg(["datName"])
    data_rows = encode_row_data_msg(tables)
    command_complete = encode_command_complete_msg("SELECT", length(tables))
    ready_for_query = <<?Z, 0, 0, 0, 5, ?I>>

    :ok = :ssl.send(conn, row_desc <> data_rows <> command_complete <> ready_for_query)
  end

  defp encode_query_msg({:ok, query}, :msgParse, rest) do
    message_size = byte_size(query) + byte_size(rest) + 6

    <<?P, message_size::integer-size(32), 0, query::binary, 0, rest::binary>>
  end

  defp encode_query_msg({:ok, query}, :msgQuery, _rest) do
    message_size = byte_size(query) + 5

    <<?Q, message_size::integer-size(32), query::binary, 0>>
  end

  defp encode_row_description_msg(fields) do
    data =
      Enum.reduce(fields, <<>>, fn field, acc ->
        acc <>
          <<field::binary, 0, 0::integer-size(32), 0::integer-size(16), 25::integer-size(32), -1::integer-size(16),
            -1::integer-size(32), 0::integer-size(16)>>
      end)

    message_size = byte_size(data) + 6

    <<?T, message_size::integer-size(32), length(fields)::integer-size(16)>> <> data
  end

  defp encode_row_data_msg(rows) do
    Enum.reduce(rows, <<>>, fn row, acc ->
      encoded_values = encode_row_values(row)
      message_size = byte_size(encoded_values) + 6

      acc <>
        <<?D, message_size::integer-size(32), length(row)::unsigned-integer-16>> <> encoded_values
    end)
  end

  defp encode_row_values(row) do
    Enum.reduce(row, <<>>, fn
      nil, acc ->
        acc <> <<-1::integer-size(32)>>

      value, acc ->
        value = to_string(value)
        acc <> <<byte_size(value)::integer-size(32), value::binary>>
    end)
  end

  defp encode_command_complete_msg(command, num_rows) do
    string = "#{command} #{num_rows}"
    message_size = byte_size(string) + 5

    <<?C, message_size::integer-size(32), string::binary, 0>>
  end
end
