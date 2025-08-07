defmodule Devhub.QueryDesk.Actions.GetSavedQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo

  @callback get_saved_query(Keyword.t()) ::
              {:ok, SavedQuery.t()} | {:error, :saved_query_not_found}
  def get_saved_query(by) do
    case Repo.get_by(SavedQuery, by) do
      %SavedQuery{} = saved_query -> {:ok, saved_query}
      nil -> {:error, :saved_query_not_found}
    end
  end
end
