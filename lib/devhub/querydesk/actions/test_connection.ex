defmodule Devhub.QueryDesk.Actions.TestConnection do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Database

  @callback test_connection(Database.t(), String.t()) :: :ok | {:error, String.t()}
  def test_connection(database, credential_id) do
    if is_nil(database.agent_id) or Application.get_env(:devhub, :agent) do
      do_test_connection(database, credential_id)
    else
      DevhubWeb.AgentConnection.send_command(
        database.agent_id,
        {__MODULE__, :do_test_connection, [database, credential_id]}
      )
    end
  end

  def do_test_connection(%{adapter: :postgres} = database, credential_id) do
    database
    |> default_opts(credential_id)
    |> Keyword.put(:parameters, application_name: "Devhub Proxy")
    |> Postgrex.Utils.default_opts()
    |> Postgrex.Protocol.connect()
    |> case do
      {:ok, %Postgrex.Protocol{sock: {:ssl, database_conn}}} ->
        :ssl.close(database_conn)
        :ok

      {:ok, %Postgrex.Protocol{sock: {:gen_tcp, database_conn}}} ->
        :gen_tcp.close(database_conn)
        :ok

      {:error, %DBConnection.ConnectionError{message: message}} ->
        {:error, message}

      {:error, %{postgres: %{message: message}}} ->
        {:error, message}

      {:error, _error} ->
        {:error, "Failed to connect to database, ensure all fields are filled out correctly"}
    end
  end

  def do_test_connection(%{adapter: :mysql} = database, credential_id) do
    database
    |> default_opts(credential_id)
    |> Keyword.put(:disconnect_on_error_codes, [])
    |> MyXQL.Connection.connect()
    |> case do
      {:ok, %MyXQL.Connection{client: %MyXQL.Client{sock: {:ssl, database_conn}}}} ->
        :ssl.close(database_conn)
        :ok

      {:ok, %MyXQL.Connection{client: %MyXQL.Client{sock: {:gen_tcp, database_conn}}}} ->
        :gen_tcp.close(database_conn)
        :ok

      {:error, %DBConnection.ConnectionError{message: message}} ->
        {:error, message}

      {:error, %MyXQL.Error{message: message}} ->
        {:error, message}

      {:error, _error} ->
        {:error, "Failed to connect to database, ensure all fields are filled out correctly"}
    end
  end

  def do_test_connection(%{adapter: :clickhouse} = database, credential_id) do
    database
    |> default_opts(credential_id)
    |> Keyword.put(:scheme, if(database.ssl, do: "https", else: "http"))
    |> Ch.Connection.connect()
    |> case do
      {:ok, conn} ->
        Mint.HTTP.close(conn)
        :ok

      {:error, %DBConnection.ConnectionError{message: message}} ->
        {:error, message}

      {:error, %Ch.Error{message: message}} ->
        {:error, message}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, reason}

      {:error, _error} ->
        {:error, "Failed to connect to database, ensure all fields are filled out correctly"}
    end
  end

  defp default_opts(database, credential_id) do
    credential = Enum.find(database.credentials, &(&1.id == credential_id))

    Enum.reject(
      [
        username: credential.username || "",
        password: credential.password || "",
        hostname: credential.hostname || database.hostname,
        port: database.port,
        database: database.database,
        ssl: if(database.ssl, do: ssl_opts(database), else: false)
      ],
      fn {_k, v} -> is_nil(v) end
    )
  end

  defp ssl_opts(database) do
    Enum.reject(
      [
        verify: :verify_none,
        cacertfile: create_ssl_file(database, :cacertfile),
        keyfile: create_ssl_file(database, :keyfile),
        certfile: create_ssl_file(database, :certfile)
      ],
      fn {_k, v} -> v == "" end
    )
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
