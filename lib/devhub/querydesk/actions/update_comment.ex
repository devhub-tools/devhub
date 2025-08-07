defmodule Devhub.QueryDesk.Actions.UpdateComment do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.QueryComment
  alias Devhub.Repo

  @callback update_comment(QueryComment.t(), map()) ::
              {:ok, QueryComment.t()} | {:error, Ecto.Changeset.t()}
  def update_comment(comment, params) do
    comment
    |> QueryComment.update_changeset(params)
    |> Repo.update()
  end
end
