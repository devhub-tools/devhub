defmodule Devhub.QueryDesk.Actions.DeleteSavedQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo

  @callback delete_saved_query(SavedQuery.t()) ::
              {:ok, SavedQuery.t()} | {:error, Ecto.Changeset.t()}
  def delete_saved_query(saved_query) do
    Repo.delete(saved_query)
  end
end
