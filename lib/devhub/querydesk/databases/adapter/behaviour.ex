defmodule Devhub.QueryDesk.Databases.AdapterBehaviour do
  @moduledoc false
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.QueryDesk.Schemas.Query

  @callback get_schema(Database.t(), user_id :: Ecto.UUID.t(), opts :: list()) :: [
              %{
                name: String.t(),
                table: String.t(),
                type: String.t(),
                fkey_table_name: String.t(),
                fkey_column_name: String.t()
              }
            ]

  @callback parse_query(Query.t()) :: map() | {:error, String.t()}

  @callback get_table_data(Database.t(), user_id :: Ecto.UUID.t(), table :: String.t(), opts :: list()) ::
              {:ok, Postgrex.Result.t() | MyXQL.Result.t(), Query.t()} | {:error, any()}
end
