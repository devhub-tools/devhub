defmodule Devhub.QueryDesk.Actions.SetupDefaultDatabase do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Users.Schemas.Organization
  alias Ecto.Adapters.SQL

  require Logger

  @doc """
  This sets up the local devhub database as an example database for new accounts.
  """
  @callback setup_default_database(Organization.t()) :: {:ok, Database.t()} | {:error, term()}
  def setup_default_database(organization) do
    config = Application.get_env(:devhub, Devhub.Repo)

    case QueryDesk.get_database(organization_id: organization.id, database: config[:database]) do
      {:ok, _database} ->
        :ok

      {:error, :database_not_found} ->
        credentials = setup_credentials(config)

        params = %{
          organization_id: organization.id,
          name: "Devhub",
          adapter: :postgres,
          hostname: config[:hostname],
          port: config[:port],
          database: config[:database],
          restrict_access: true,
          ssl: is_list(config[:ssl]),
          cacertfile: if(File.exists?("/etc/secrets/ca.cert"), do: File.read!("/etc/secrets/ca.cert")),
          keyfile: if(File.exists?("/etc/secrets/client.key"), do: File.read!("/etc/secrets/client.key")),
          certfile: if(File.exists?("/etc/secrets/client.cert"), do: File.read!("/etc/secrets/client.cert")),
          credentials: credentials
        }

        QueryDesk.create_database(params)
    end
  rescue
    error ->
      Logger.error("Failed to setup Devhub database: #{inspect(error)}")
      error
  end

  defp setup_credentials(config) do
    encrypted_password = generate_scram_password(config[:password])

    with {:ok, _result} <-
           SQL.query(
             Devhub.Repo,
             "CREATE ROLE devhub_readonly WITH LOGIN ENCRYPTED PASSWORD '#{encrypted_password}';"
           ),
         {:ok, _result} <- SQL.query(Devhub.Repo, "GRANT CONNECT ON DATABASE #{config[:database]} TO devhub_readonly;"),
         {:ok, _result} <- SQL.query(Devhub.Repo, "GRANT USAGE ON SCHEMA public TO devhub_readonly;"),
         {:ok, _result} <-
           SQL.query(Devhub.Repo, "GRANT SELECT ON ALL TABLES IN SCHEMA public TO devhub_readonly;"),
         {:ok, _result} <-
           SQL.query(
             Devhub.Repo,
             "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO devhub_readonly;"
           ) do
      [
        %{
          default_credential: true,
          reviews_required: 0,
          username: "devhub_readonly",
          password: config[:password]
        },
        %{
          default_credential: false,
          reviews_required: 1,
          username: config[:username],
          password: config[:password]
        }
      ]
    else
      _failed_to_create_readonly_user ->
        [
          %{
            default_credential: true,
            reviews_required: 0,
            username: config[:username],
            password: config[:password]
          }
        ]
    end
  end

  defp generate_scram_password(password) do
    salt = :crypto.strong_rand_bytes(16)
    iterations = 32_768

    salted_password = :crypto.pbkdf2_hmac(:sha256, password, salt, iterations, 32)
    client_key = :crypto.mac(:hmac, :sha256, salted_password, "Client Key")
    stored_key = :crypto.hash(:sha256, client_key)
    server_key = :crypto.mac(:hmac, :sha256, salted_password, "Server Key")

    encoded_salt = Base.encode64(salt)
    encoded_stored_key = Base.encode64(stored_key)
    encoded_server_key = Base.encode64(server_key)

    "SCRAM-SHA-256$#{iterations}:#{encoded_salt}$#{encoded_stored_key}:#{encoded_server_key}"
  end
end
