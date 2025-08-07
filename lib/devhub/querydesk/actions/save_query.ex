defmodule Devhub.QueryDesk.Actions.SaveQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SavedQuery
  alias Devhub.Repo

  @callback save_query(map()) :: {:ok, SavedQuery.t()} | {:error, Ecto.Changeset.t()}
  def save_query(params) do
    params
    |> SavedQuery.changeset()
    |> Repo.insert()
  end
end
