defmodule Devhub.QueryDesk.Actions.SaveSharedQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  @callback save_shared_query(map()) :: {:ok, SharedQuery.t()} | {:error, Ecto.Changeset.t()}
  def save_shared_query(params) do
    params
    |> SharedQuery.changeset()
    |> Repo.insert()
  end
end
