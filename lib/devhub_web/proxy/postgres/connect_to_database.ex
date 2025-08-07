defmodule DevhubWeb.Proxy.Postgres.ConnectToDatabase do
  @moduledoc false

  alias Devhub.QueryDesk
  alias DevhubWeb.Proxy.Postgres.ClientState
  alias DevhubWeb.Proxy.Postgres.DatabaseState
  alias Phoenix.PubSub

  def connect_to_database(
        %ClientState{organization_user: organization_user, connect_params: connect_params, database_conn: nil} = state
      ) do
    {group, database} =
      case String.split(connect_params["database"], ":") do
        [database] -> {nil, database}
        [group, database] -> {group, database}
      end

    # only allow connections if no reviews are required
    with {:ok, %{default_credential: %{reviews_required: 0}} = database} <-
           QueryDesk.get_database(name: database, group: group, organization_id: organization_user.organization_id),
         state = %{state | database: database},
         true <- QueryDesk.can_access_database?(database, organization_user) do
      {:ok, database_conn, parameters, _pid} = do_open_database_connection(database, state)

      auth_ok = <<?R, 0, 0, 0, 8, 0, 0, 0, 0>>

      params_msg =
        Enum.map_join(parameters, fn {k, v} ->
          <<?S, byte_size(k <> v) + 6::integer-32, k::binary, 0, v::binary, 0>>
        end)

      ready = <<?Z, 0, 0, 0, 5, ?I>>

      :ok = :ssl.send(state.conn, auth_ok <> params_msg <> ready)

      {:ok, %{state | database_conn: database_conn}}
    else
      _error ->
        :ssl.close(state.conn)
        {:error, :not_authorized}
    end
  end

  def do_open_database_connection(database, %ClientState{conn: client_conn} = client_state) do
    if is_nil(database.agent_id) or Application.get_env(:devhub, :agent) do
      {:ok, database_conn} = open_database_connection(database)

      {:ok, pid} =
        Task.Supervisor.start_child(Devhub.TaskSupervisor, fn ->
          # read messages coming directly from database and send to client or proxy
          read_database(%DatabaseState{conn: database_conn, database: database, client_conn: client_conn})
        end)

      case database_conn do
        %Postgrex.Protocol{sock: {:ssl, socket}} ->
          :ok = :ssl.controlling_process(socket, pid)

        %Postgrex.Protocol{sock: {:gen_tcp, port}} when is_port(port) ->
          :ok = :gen_tcp.controlling_process(port, pid)
      end

      %Postgrex.Protocol{parameters: parameters} = database_conn

      {:ok, parameters} = Postgrex.Parameters.fetch(parameters)

      {:ok, database_conn, parameters, pid}
    else
      ref = Ecto.UUID.generate()
      client_state = %{client_state | conn: ref}

      {:ok, database_conn, parameters, _pid} =
        DevhubWeb.AgentConnection.send_command(
          database.agent_id,
          {__MODULE__, :do_open_database_connection, [database, client_state]}
        )

      {:ok, pid} =
        Task.Supervisor.start_child(Devhub.TaskSupervisor, fn ->
          # read messages from proxy and send to client
          PubSub.subscribe(Devhub.PubSub, ref)
          read_database(%DatabaseState{conn: ref, database: database, client_conn: client_conn})
        end)

      {:ok, {ref, database_conn}, parameters, pid}
    end
  end

  defp read_database(%DatabaseState{conn: conn, client_conn: client_conn} = state) do
    case read_line(conn) do
      {:ok, data} ->
        case client_conn do
          ref when is_binary(ref) ->
            Phoenix.PubSub.broadcast(Devhub.PubSub, "agent", {ref, {:message_from_database, {:ok, data}}})

          client_conn ->
            :ssl.send(client_conn, data)
        end

        read_database(state)

      _error ->
        case client_conn do
          ref when is_binary(ref) ->
            Phoenix.PubSub.broadcast(Devhub.PubSub, "agent", {ref, {:message_from_database, {:error, :closed}}})

          client_conn ->
            :ssl.close(client_conn)
        end
    end
  end

  defp read_line(%Postgrex.Protocol{sock: {:ssl, socket}}) do
    :ssl.recv(socket, 0)
  end

  defp read_line(%Postgrex.Protocol{sock: {:gen_tcp, port}}) when is_port(port) do
    :gen_tcp.recv(port, 0)
  end

  defp read_line(ref) when is_binary(ref) do
    receive do
      {:message_from_database, message} -> message
    end
  end

  defp open_database_connection(database) do
    timeout_query = "SET statement_timeout = 600000;"
    timeout_msg = <<?Q, byte_size(timeout_query) + 5::integer-32, timeout_query::binary, 0>>

    ssl_opts =
      Enum.reject(
        [
          verify: :verify_none,
          cacertfile: create_ssl_file(database, :cacertfile),
          keyfile: create_ssl_file(database, :keyfile),
          certfile: create_ssl_file(database, :certfile)
        ],
        fn {_k, v} -> v == "" end
      )

    [
      username: database.default_credential.username,
      password: database.default_credential.password,
      hostname: database.default_credential.hostname || database.hostname,
      port: database.port,
      database: database.database,
      parameters: [
        application_name: "Devhub Proxy"
      ],
      ssl: if(database.ssl, do: ssl_opts, else: false)
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Postgrex.Utils.default_opts()
    |> Postgrex.Protocol.connect()
    |> then(fn
      {:ok, %Postgrex.Protocol{sock: {:ssl, socket}} = database_conn} ->
        :ssl.setopts(socket, active: false)
        :ssl.send(socket, timeout_msg)
        {:ok, <<67, 0, 0, 0, 8, 83, 69, 84, 0, 90, 0, 0, 0, 5, 73>>} = :ssl.recv(socket, 0)

        {:ok, database_conn}

      {:ok, %Postgrex.Protocol{sock: {:gen_tcp, port}} = database_conn} ->
        :inet.setopts(port, active: false)
        :ok = :gen_tcp.send(port, timeout_msg)
        {:ok, <<67, 0, 0, 0, 8, 83, 69, 84, 0, 90, 0, 0, 0, 5, 73>>} = :gen_tcp.recv(port, 0)

        {:ok, database_conn}
    end)
  end

  defp create_ssl_file(database, key) do
    if data = Map.get(database, key) do
      filename = "/tmp/#{database.id}-#{key}.pem"
      File.write!(filename, data)
      filename
    else
      ""
    end
  end
end
