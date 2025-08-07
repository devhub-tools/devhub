defmodule DevhubWeb.Proxy.Postgres.SendToDatabase do
  @moduledoc false

  alias DevhubWeb.Proxy.Postgres.ClientState
  alias DevhubWeb.Proxy.Postgres.DatabaseState

  require Logger

  def send_to_database(%ClientState{} = state, binary) do
    send_to_database(
      # messages shouldn't be sent back on this state so we don't set client_conn
      %DatabaseState{conn: state.database_conn, database: state.database},
      binary
    )
  end

  def send_to_database(%DatabaseState{conn: %Postgrex.Protocol{sock: {:ssl, socket}}}, binary) do
    :ssl.send(socket, binary)
  end

  def send_to_database(%DatabaseState{conn: %Postgrex.Protocol{sock: {:gen_tcp, port}}}, binary) when is_port(port) do
    :gen_tcp.send(port, binary)
  end

  def send_to_database(%DatabaseState{database: database, conn: {ref, database_conn}} = state, binary) do
    DevhubWeb.AgentConnection.send_command(
      database.agent_id,
      {__MODULE__, :send_to_database, [%{state | conn: database_conn}, binary]},
      ref: ref
    )
  end
end
