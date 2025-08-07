defmodule Devhub.QueryDesk.Utils.GetConnectionPid do
  @moduledoc false

  alias Devhub.QueryDesk.ClickHouseRepo
  alias Devhub.QueryDesk.MySQLRepo
  alias Devhub.QueryDesk.PostgresRepo
  alias Devhub.QueryDesk.PostgresTypes
  alias Devhub.QueryDesk.RepoRegistry
  alias Devhub.QueryDesk.RepoSupervisor
  alias Devhub.QueryDesk.Schemas.DatabaseCredential

  @spec get_connection_pid(DatabaseCredential.t(), Keyword.t()) :: {:ok, pid()}
  def get_connection_pid(%DatabaseCredential{} = credential, opts \\ []) do
    temporary = Keyword.get(opts, :temporary, false)

    credential
    |> format_credential()
    |> do_get_connection_pid(temporary, opts)
  end

  defp do_get_connection_pid(
         %{
           username: username,
           password: password,
           database: %{adapter: adapter, hostname: hostname, database: database, ssl: ssl, port: port}
         },
         true,
         opts
       ) do
    # :sqlserver -> Devhub.QueryDesk.SQLServerRepo
    repo_module = repo_module(adapter)

    [
      name: {:via, Registry, {RepoRegistry, Ecto.UUID.generate()}},
      hostname: hostname,
      port: port,
      username: username,
      password: password,
      database: database,
      pool_size: 1,
      ssl: ssl,
      log: false
    ]
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> add_adapter_specific_config(adapter, opts)
    |> repo_module.start_link()
  end

  defp do_get_connection_pid(
         %{
           id: id,
           username: username,
           password: password,
           database: %{adapter: adapter, hostname: hostname, database: database, ssl: ssl, port: port}
         },
         _temp,
         _opts
       ) do
    case Registry.lookup(RepoRegistry, id) do
      [{pid, _value}] ->
        {:ok, pid}

      _not_found ->
        # :sqlserver -> Devhub.QueryDesk.SQLServerRepo
        repo_module = repo_module(adapter)

        config =
          [
            name: {:via, Registry, {RepoRegistry, id}},
            hostname: hostname,
            port: port,
            username: username,
            password: password,
            database: database,
            pool_size: 1,
            ssl: ssl,
            log: false,
            queue_target: 10_000
          ]
          |> Enum.reject(fn {_k, v} -> is_nil(v) end)
          |> add_adapter_specific_config(adapter, [])

        DynamicSupervisor.start_child(
          RepoSupervisor,
          %{
            id: id,
            # just let it die, it will be recreated on the next query
            restart: :temporary,
            start: {repo_module, :start_link, [config]}
          }
        )
    end
  end

  defp format_credential(credential) do
    ssl = credential.database.ssl

    ssl_opts =
      Enum.reject(
        [
          verify: :verify_none,
          cacertfile: create_ssl_file(credential.database, :cacertfile),
          keyfile: create_ssl_file(credential.database, :keyfile),
          certfile: create_ssl_file(credential.database, :certfile)
        ],
        fn {_k, v} -> is_nil(v) end
      )

    %{
      id: credential.id,
      username: credential.username,
      password: credential.password,
      database: %{
        adapter: credential.database.adapter,
        hostname: credential.hostname || credential.database.hostname,
        port: credential.database.port,
        database: credential.database.database,
        ssl: if(ssl, do: ssl_opts, else: false)
      }
    }
  end

  defp add_adapter_specific_config(config, :postgres, opts) do
    timeout = Keyword.get(opts, :timeout, 10_000)

    Keyword.merge(config,
      types: PostgresTypes,
      after_connect: &Postgrex.query!(&1, "SET statement_timeout = #{timeout}", []),
      timeout: timeout
    )
  end

  defp add_adapter_specific_config(config, :mysql, opts) do
    timeout = Keyword.get(opts, :timeout, 10_000)

    Keyword.merge(config,
      after_connect: &MyXQL.query!(&1, "SET SESSION max_execution_time = #{timeout}", []),
      timeout: timeout
    )
  end

  defp add_adapter_specific_config(config, :clickhouse, opts) do
    timeout = Keyword.get(opts, :timeout, 10_000)

    Keyword.merge(config,
      scheme: if(config[:ssl], do: "https", else: "http"),
      after_connect: &Ch.query!(&1, "SET max_execution_time = #{timeout}", []),
      timeout: timeout
    )
  end

  defp add_adapter_specific_config(config, _adapter, _opts), do: config

  defp create_ssl_file(database, key) do
    if data = Map.get(database, key) do
      tmp = System.tmp_dir!()
      filename = Path.join(tmp, "#{database.id}-#{key}.pem")
      File.write!(filename, data)
      filename
    end
  end

  defp repo_module(:postgres), do: PostgresRepo
  defp repo_module(:mysql), do: MySQLRepo
  defp repo_module(:clickhouse), do: ClickHouseRepo
end
