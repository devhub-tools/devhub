defmodule Devhub.QueryDesk.Actions.DeleteSharedQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo

  @callback delete_shared_query(SharedQuery.t()) :: {:ok, SharedQuery.t()} | {:error, Ecto.Changeset.t()}
  def delete_shared_query(shared_query) do
    Repo.delete(shared_query)
  end
end
