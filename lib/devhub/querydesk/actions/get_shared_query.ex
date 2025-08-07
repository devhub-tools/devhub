defmodule Devhub.QueryDesk.Actions.GetSharedQuery do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  @callback get_shared_query(Keyword.t()) :: {:ok, SharedQuery.t()} | {:error, :shared_query_expired}
  def get_shared_query(by) do
    query =
      from s in SharedQuery,
        left_join: p in assoc(s, :permissions),
        where: ^by,
        where: s.expires_at > ^DateTime.utc_now()

    case Repo.one(query) do
      %SharedQuery{} = shared_query ->
        {:ok,
         Repo.preload(
           shared_query,
           :permissions
         )}

      nil ->
        {:error, :shared_query_expired}
    end
  end
end
