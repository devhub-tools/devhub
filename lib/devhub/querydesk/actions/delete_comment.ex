defmodule Devhub.QueryDesk.Actions.DeleteComment do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.QueryComment
  alias Devhub.Repo

  @callback delete_comment(QueryComment.t()) ::
              {:ok, QueryComment.t()} | {:error, Ecto.Changeset.t()}
  def delete_comment(comment) do
    Repo.delete(comment)
  end
end
