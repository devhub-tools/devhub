defmodule DevhubWeb.PostgresProxy do
  # https://www.postgresql.org/docs/11/protocol-message-formats.html
  @moduledoc false
  import DevhubWeb.Proxy.Postgres.ConnectToDatabase
  import DevhubWeb.Proxy.Postgres.HandleQuery
  import DevhubWeb.Proxy.Postgres.Handshake
  import DevhubWeb.Proxy.Postgres.ParseConnectParams
  import DevhubWeb.Proxy.Postgres.ParseMessage
  import DevhubWeb.Proxy.Postgres.SendToDatabase
  import DevhubWeb.Proxy.Postgres.VerifyPassword

  alias Devhub.Users
  alias DevhubWeb.Proxy.Postgres.ClientState

  require Logger

  def accept do
    port = Application.get_env(:devhub, __MODULE__)[:port]

    {:ok, socket} = :gen_tcp.listen(port, mode: :binary, packet: 0, active: false, reuseaddr: true)

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client_conn} = :gen_tcp.accept(socket)

    state = %ClientState{conn: client_conn}

    {:ok, pid} =
      Task.Supervisor.start_child(Devhub.TaskSupervisor, fn ->
        read_client(state, nil)
      end)

    :ok = :gen_tcp.controlling_process(client_conn, pid)

    loop_acceptor(socket)
  end

  defp read_client(%ClientState{conn: conn} = state, nil) do
    with {:ok, data} <- read_line(conn) do
      handle_message(state, parse_message(data))
    end
  end

  defp read_client(%ClientState{conn: conn} = state, fun) do
    with {:ok, data} <- read_line(conn) do
      r = fun.(data)

      handle_message(state, r)
    end
  end

  defp read_line({:sslsocket, _port, _pids} = socket) do
    :ssl.recv(socket, 0)
  end

  defp read_line(socket) when is_port(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp handle_message(%ClientState{} = state, {:ok, {{:msgSSLRequest, nil}, _msg}, _rest} = full_msg) do
    state
    |> handshake()
    |> next_message(full_msg)
  end

  # clients auto retry without tls if they get a fatal error
  defp handle_message(%ClientState{conn: conn}, _full_msg) when is_port(conn) do
    error = <<?S, "FATAL", 0, ?V, "FATAL", 0, ?C, "28P01", 0, ?M, "invalid auth token", 0, ?R, "auth_failed", 0, 0>>

    length = byte_size(error) + 4
    msg = <<?E, length::integer-size(32), error::binary>>
    :gen_tcp.send(conn, msg)
  end

  defp handle_message(%ClientState{conn: conn} = state, {:ok, {{:msgStartup, nil}, msg}, _rest} = full_msg) do
    # send password required auth message
    :ok = :ssl.send(conn, <<?R, 0, 0, 0, 23, 0, 0, 0, 10, "SCRAM-SHA-256", 0, 0>>)

    state
    |> parse_connect_params(msg)
    |> next_message(full_msg)
  end

  # First client SASL message
  defp handle_message(
         %ClientState{conn: conn} = state,
         {:ok,
          {{:msgPasswordMessage, _tag},
           <<_len::unsigned-integer-32, "SCRAM-SHA-256", 0, _sasl_len::unsigned-integer-32, sasl_data::binary>>},
          _rest} = full_msg
       ) do
    with {:ok, %{proxy_password: %{salt: salt}} = user} <- Users.get_by(email: state.connect_params["user"]) do
      server_nonce = 16 |> :crypto.strong_rand_bytes() |> Base.encode64()

      [channel_binding, "", "n=" <> username, "r=" <> client_nonce] = String.split(sasl_data, ",")
      message = "r=#{client_nonce}#{server_nonce},s=#{salt},i=32768"
      length = byte_size(message) + 8

      :ok = :ssl.send(conn, <<?R, length::integer-size(32), 0, 0, 0, 11, message::binary>>)

      next_message(
        %{
          state
          | user: user,
            scram_state: %{
              client_nonce: client_nonce,
              server_nonce: server_nonce,
              channel_binding: channel_binding == "y",
              username: username
            }
        },
        full_msg
      )
    end
  end

  # Final client SASL message
  defp handle_message(
         %ClientState{} = state,
         {:ok, {{:msgPasswordMessage, _tag}, <<_len::unsigned-integer-32, sasl_data::binary>>}, _rest} = full_msg
       ) do
    with {:ok, state} <- verify_password(sasl_data, state),
         {:ok, state} <- connect_to_database(state) do
      next_message(state, full_msg)
    end
  end

  defp handle_message(
         %ClientState{} = state,
         {:ok, {{:msgQuery, _c}, <<_len::unsigned-integer-32, query_data::binary>>}, _rest} = msg
       ) do
    query = String.trim_trailing(query_data, <<0>>)

    handle_query(query, state, :msgQuery)

    next_message(state, msg)
  end

  defp handle_message(
         %ClientState{} = state,
         {:ok, {{:msgParse, c}, <<_len::unsigned-integer-32, query_data::binary>> = msg}, _rest} = full_msg
       ) do
    {_name, query_data} = decode_string(query_data)

    case decode_string(query_data) do
      # if an empty query we can just pass to the database
      {"", _empty} -> :ok = send_to_database(state, <<c, msg::binary>>)
      {query, rest} -> handle_query(query, state, :msgParse, rest)
    end

    next_message(state, full_msg)
  end

  defp handle_message(%ClientState{} = state, {:ok, {{:msgTerminate, c}, msg}, _rest}) do
    :ok = send_to_database(state, <<c, msg::binary>>)
  end

  defp handle_message(%ClientState{} = state, {:ok, {{msg_type, c}, msg}, _rest} = full_msg)
       when msg_type in [:msgBind, :msgErrorResponse, :msgSync] do
    :ok = send_to_database(state, <<c, msg::binary>>)

    next_message(state, full_msg)
  end

  defp handle_message(%ClientState{} = state, {:ok, {{:msgDataRow, c}, <<0, 0, 0, 6, 80, 0>> = msg}, _rest} = full_msg) do
    :ok = send_to_database(state, <<c, msg::binary>>)

    next_message(%ClientState{} = state, full_msg)
  end

  defp handle_message(%ClientState{} = state, msg) do
    Logger.info("unmatched msg: #{inspect(msg)}")
    next_message(state, msg)
  end

  defp next_message(%ClientState{} = state, {:ok, {{_msgType, _c}, _data}, ""}) do
    read_client(state, nil)
  end

  defp next_message(%ClientState{} = state, {:ok, {{_msgType, _c}, _data}, rest}) do
    handle_message(state, parse_message(rest))
  end

  defp next_message(%ClientState{} = state, {:continuation, continuation}) do
    read_client(state, continuation)
  end

  defp decode_string(bin) do
    {pos, 1} = :binary.match(bin, <<0>>)
    {string, <<0, rest::binary>>} = :erlang.split_binary(bin, pos)
    {string, rest}
  end
end
