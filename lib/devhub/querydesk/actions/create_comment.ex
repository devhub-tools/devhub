defmodule Devhub.QueryDesk.Actions.CreateComment do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.QueryDesk.Schemas.QueryComment
  alias Devhub.Repo
  alias Devhub.Users.User

  @callback create_comment(Query.t(), User.t(), String.t()) ::
              {:ok, QueryComment.t()} | {:error, Ecto.Changeset.t()}
  def create_comment(query, user, comment) do
    result =
      %{
        comment: comment,
        organization_id: query.organization_id,
        created_by_user_id: user.id,
        query_id: query.id
      }
      |> QueryComment.create_changeset()
      |> Repo.insert()

    with {:ok, comment} <- result do
      {:ok, Repo.preload(comment, :created_by_user)}
    end
  end
end
