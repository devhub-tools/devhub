defmodule Devhub.QueryDesk.Actions.GetQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  @callback get_query(Keyword.t()) :: {:ok, Query.t()} | {:error, :query_not_found}
  def get_query(by) do
    case Repo.get_by(Query, by) do
      %Query{} = query -> {:ok, Repo.preload(query, credential: :database)}
      nil -> {:error, :query_not_found}
    end
  end
end
