defmodule Devhub.QueryDesk.Databases.Adapter.ClickHouse do
  @moduledoc false
  @behaviour Devhub.QueryDesk.Databases.AdapterBehaviour

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.AdapterBehaviour
  alias Devhub.QueryDesk.Databases.Utils.GetTableData
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.Repo

  @impl AdapterBehaviour
  def get_schema(%{default_credential: %Ecto.Association.NotLoaded{}}, _user_id, _opts),
    do: raise("default_credential not loaded")

  def get_schema(%{default_credential: %{reviews_required: 0}} = database, user_id, _opts) do
    query_string =
      """
      SELECT
        DISTINCT
          table AS table_name,
          name AS column_name,
          type AS data_type
      FROM system.columns
      WHERE
          database = '#{database.database}';
      """

    placeholders = %{timestamp: DateTime.utc_now()}

    with {:ok, query} <-
           QueryDesk.create_query(%{
             organization_id: database.organization_id,
             credential_id: database.default_credential.id,
             query: query_string,
             is_system: true,
             user_id: user_id
           }),
         {:ok, %{rows: rows}, _query} <- QueryDesk.run_query(query) do
      columns =
        Enum.map(rows, fn [table, column, type] ->
          %{
            id: UXID.generate!(prefix: "col"),
            organization_id: database.organization_id,
            database_id: database.id,
            name: column,
            table: table,
            type: type,
            inserted_at: {:placeholder, :timestamp},
            updated_at: {:placeholder, :timestamp}
          }
        end)

      {_num, records} =
        Repo.insert_all(DatabaseColumn, columns,
          conflict_target: [:database_id, :table, :name],
          on_conflict: {:replace, [:type]},
          returning: true,
          placeholders: placeholders
        )

      records
    end
  end

  # we don't currently support getting the schema if the default credential
  # requires reviews
  def get_schema(_database, _user_id, _opts) do
    []
  end

  @impl AdapterBehaviour
  def parse_query(_query) do
    {:error, "Query parsing is not supported for ClickHouse"}
  end

  @impl AdapterBehaviour
  defdelegate get_table_data(database, user_id, table, opts \\ []), to: GetTableData
end
