defmodule Devhub.QueryDesk.Databases.Utils.GetTableData do
  @moduledoc false

  alias Devhub.QueryDesk

  def get_table_data(database, user_id, table, opts \\ []) do
    sql = add_filters("SELECT * FROM `#{table}`", opts[:filters] || [])

    sql =
      case opts[:order_by] do
        %{direction: direction, field: field} ->
          direction =
            case direction do
              :asc -> "ASC"
              :desc -> "DESC"
            end

          sql <> " ORDER BY `#{field}` #{direction}"

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
      filter = add_filter(filter)

      "`#{column}` #{filter}"
    end)
    |> then(fn
      [] -> sql
      filters -> sql <> " WHERE " <> Enum.join(filters, " AND ")
    end)
  end

  defp add_filter(%{value: value, operator: :equals}), do: ~s(= '#{value}')
  defp add_filter(%{value: value, operator: :not_equals}), do: ~s(!= '#{value}')
  defp add_filter(%{value: value, operator: :contains}), do: ~s(LIKE '%#{value}%')
  defp add_filter(%{value: value, operator: :does_not_contain}), do: ~s(NOT LIKE '%#{value}%')
  defp add_filter(%{value: value, operator: :like}), do: ~s(LIKE '#{value}')
  defp add_filter(%{operator: :is_null}), do: ~s(IS NULL)
  defp add_filter(%{operator: :is_not_null}), do: ~s(IS NOT NULL)

  defp add_filter(%{value: value, operator: operator})
       when operator in [:greater_than, :less_than, :greater_than_or_equal, :less_than_or_equal] do
    operator =
      case operator do
        :greater_than -> ">"
        :less_than -> "<"
        :greater_than_or_equal -> ">="
        :less_than_or_equal -> "<="
      end

    ~s(#{operator} '#{value}')
  end
end
