defmodule Devhub.Integrations.AI.Utils.FormatDatabaseSchema do
  @moduledoc false

  def format_database_schema(schema) do
    schema
    |> Enum.group_by(& &1.table)
    |> Enum.map_join("\n", fn {table, columns} ->
      fields =
        Enum.map(columns, fn
          column ->
            field_info =
              [
                String.upcase(column.type),
                (column.is_primary_key && "PRIMARY KEY") || nil,
                (column.fkey_table_name && "FOREIGN KEY REFERENCES #{column.fkey_table_name}") || nil
              ]
              |> Enum.reject(&is_nil/1)
              |> Enum.join(", ")

            """
            - #{column.name} (#{field_info})
            """
        end)

      """
      #{table}:
      #{fields}
      """
    end)
  end
end
