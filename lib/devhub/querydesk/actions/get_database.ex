defmodule Devhub.QueryDesk.Actions.GetDatabase do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Repo

  @callback get_database(Keyword.t()) :: {:ok, Database.t()} | {:error, :database_not_found}
  @callback get_database(Keyword.t(), Keyword.t()) :: {:ok, Database.t()} | {:error, :database_not_found}
  def get_database(by, opts \\ []) do
    preload = [:credentials, :default_credential, :permissions] ++ Keyword.get(opts, :preload, [])

    from(Database)
    |> maybe_preload_columns(opts[:table])
    |> query_filter(by)
    |> Repo.one()
    |> case do
      %Database{} = database ->
        {:ok, Repo.preload(database, preload)}

      nil ->
        {:error, :database_not_found}
    end
  end

  defp maybe_preload_columns(query, table) when is_binary(table) do
    from d in query,
      left_join: c in assoc(d, :columns),
      on: c.table == ^table,
      preload: [columns: c]
  end

  defp maybe_preload_columns(query, _table), do: query
end
