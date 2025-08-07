defmodule Devhub.QueryDesk.Databases.Adapter.Postgres do
  @moduledoc false
  @behaviour Devhub.QueryDesk.Databases.AdapterBehaviour

  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.AdapterBehaviour
  alias Devhub.QueryDesk.QueryParserService
  alias Devhub.QueryDesk.Schemas.DatabaseColumn
  alias Devhub.Repo

  @impl AdapterBehaviour
  def get_schema(%{default_credential: %Ecto.Association.NotLoaded{}}, _user_id, _opts),
    do: raise("default_credential not loaded")

  def get_schema(%{default_credential: %{reviews_required: 0}} = database, user_id, opts) do
    schema = opts[:schema] || "public"

    query_string =
      """
      SELECT
          DISTINCT ON (cls.relname, attr.attname)
          cls.relname AS table_name,
          attr.attname AS column_name,
          col.ordinal_position AS position,
          CASE
              WHEN typ.typname LIKE '\\_%' THEN substring(typ.typname from 2) || '[]'
              ELSE typ.typname
          END AS data_type,
          COALESCE(idx.indisprimary, false) AS is_primary_key,
          fk.fk_table_name AS fkey_table_name,
          fk.fk_column_name AS fkey_column_name
      FROM
          pg_attribute attr
      JOIN
          pg_class cls ON attr.attrelid = cls.oid
      JOIN
        information_schema.columns col ON col.table_name = cls.relname AND col.column_name = attr.attname
      JOIN
          pg_type typ ON attr.atttypid = typ.oid
      JOIN
          pg_namespace nsp ON cls.relnamespace = nsp.oid AND nsp.nspname = '#{schema}'
      LEFT JOIN
          pg_index idx ON cls.oid = idx.indrelid and attr.attnum = any(idx.indkey)
      LEFT JOIN (
          SELECT
              con.conrelid,
              con.confrelid,
              a.attname AS fk_column_name,
              cl.relname AS fk_table_name,
              unnest(con.conkey) AS conkey
          FROM
              pg_constraint con
          JOIN
            pg_class cl ON cl.oid = con.confrelid
          JOIN
            pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = ANY(con.confkey)
          WHERE
            con.contype = 'f'
      ) fk ON fk.conrelid = cls.oid AND fk.conkey = attr.attnum
      WHERE
          attr.attnum > 0
          AND NOT attr.attisdropped
          AND cls.relkind = 'r';
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
        Enum.map(rows, fn [table, column, position, type, is_primary_key, fkey_table_name, fkey_column_name] ->
          %{
            id: UXID.generate!(prefix: "col"),
            organization_id: database.organization_id,
            database_id: database.id,
            name: column,
            table: table,
            position: position,
            type: type,
            is_primary_key: is_primary_key,
            fkey_table_name: fkey_table_name,
            fkey_column_name: fkey_column_name,
            inserted_at: {:placeholder, :timestamp},
            updated_at: {:placeholder, :timestamp}
          }
        end)

      column_map = Map.new(columns, fn column -> {column.table <> "." <> column.name, column.id} end)

      # Delete columns that are no longer present
      database
      |> Repo.preload(:columns)
      |> Map.get(:columns, [])
      |> Enum.each(fn column ->
        still_exists = Map.has_key?(column_map, "#{column.table}.#{column.name}")

        if not still_exists do
          Repo.delete(column)
        end
      end)

      {_num, records} =
        Repo.insert_all(DatabaseColumn, columns,
          conflict_target: [:database_id, :table, :name],
          on_conflict: {:replace, [:is_primary_key, :type, :fkey_table_name, :fkey_column_name, :position]},
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
  def parse_query(query) do
    QueryParserService.parse_query(query.query)
  end

  @impl AdapterBehaviour
  def get_table_data(database, user_id, table, opts) do
    sql = add_filters(~s(SELECT * FROM "#{table}"), opts[:filters] || [])

    sql =
      case opts[:order_by] do
        %{direction: direction, field: field} ->
          direction =
            case direction do
              :asc -> "ASC"
              :desc -> "DESC"
            end

          sql <> ~s( ORDER BY "#{field}" #{direction})

        _value ->
          sql
      end

    QueryDesk.create_query(%{
      organization_id: database.organization_id,
      credential_id: database.default_credential.id,
      query: sql <> " LIMIT 500",
      is_system: false,
      user_id: user_id
    })
  end

  defp add_filters(sql, filters) do
    filters
    |> Enum.map(fn %{column: column} = filter ->
      add_filter(column, filter)
    end)
    |> then(fn
      [] -> sql
      filters -> sql <> " WHERE " <> Enum.join(filters, " AND ")
    end)
  end

  defp add_filter(column, %{value: value, operator: :equals}), do: ~s("#{column}" = '#{value}')
  defp add_filter(column, %{value: value, operator: :not_equals}), do: ~s("#{column}" != '#{value}')
  defp add_filter(column, %{value: value, operator: :contains}), do: ~s("#{column}"::text ILIKE '%#{value}%')
  defp add_filter(column, %{value: value, operator: :does_not_contain}), do: ~s("#{column}"::text NOT ILIKE '%#{value}%')
  defp add_filter(column, %{value: value, operator: :like}), do: ~s("#{column}"::text ILIKE '#{value}')
  defp add_filter(column, %{operator: :is_null}), do: ~s("#{column}" IS NULL)
  defp add_filter(column, %{operator: :is_not_null}), do: ~s("#{column}" IS NOT NULL)

  defp add_filter(column, %{value: value, operator: operator})
       when operator in [:greater_than, :less_than, :greater_than_or_equal, :less_than_or_equal] do
    operator =
      case operator do
        :greater_than -> ">"
        :less_than -> "<"
        :greater_than_or_equal -> ">="
        :less_than_or_equal -> "<="
      end

    ~s("#{column}" #{operator} '#{value}')
  end
end
