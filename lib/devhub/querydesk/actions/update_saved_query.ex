defmodule Devhub.QueryDesk.Actions.UpdateSavedQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo

  @callback update_saved_query(SavedQuery.t(), map()) ::
              {:ok, SavedQuery.t()} | {:error, Ecto.Changeset.t()}
  def update_saved_query(saved_query, params) do
    saved_query
    |> SavedQuery.changeset(params)
    |> Repo.update()
  end
end
