defmodule Devhub.QueryDesk.Actions.UpdateQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo

  @callback update_query(Query.t(), map()) :: {:ok, Query.t()} | {:error, Ecto.Changeset.t()}
  def update_query(query, params) do
    query
    |> Query.changeset(params)
    |> Repo.update()
  end
end
