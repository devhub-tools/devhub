defmodule Devhub.QueryDesk.Databases.Adapter do
  @moduledoc false
  use Nebulex.Caching

  alias Devhub.QueryDesk.Databases.Adapter.ClickHouse
  alias Devhub.QueryDesk.Databases.Adapter.MySQL
  alias Devhub.QueryDesk.Databases.Adapter.Postgres

  @decorate cacheable(
              cache: Devhub.QueryDesk.Cache,
              key: "schema:#{database.id}",
              opts: [ttl: to_timeout(minute: 15)],
              match: fn list -> not Enum.empty?(list) end
            )
  def get_schema(database, user_id, opts \\ []) do
    adapter_module(database.adapter).get_schema(database, user_id, opts)
  end

  def parse_query(query) do
    adapter_module(query.credential.database.adapter).parse_query(query)
  end

  def get_table_data(database, user_id, table, opts \\ []) do
    adapter_module(database.adapter).get_table_data(database, user_id, table, opts)
  end

  defp adapter_module(:postgres), do: Postgres
  defp adapter_module(:mysql), do: MySQL
  defp adapter_module(:clickhouse), do: ClickHouse
end
