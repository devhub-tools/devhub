defmodule Devhub.QueryDesk.Actions.DeleteQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Repo
  alias Devhub.Users.User

  @callback delete_query(Query.t(), User.t()) ::
              {:ok, Query.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_allowed_to_delete_query}
  def delete_query(%{executed_at: executed_at}, _user) when is_struct(executed_at) do
    {:error, :not_allowed_to_delete_query}
  end

  def delete_query(query, user) do
    organization_user =
      Enum.find(user.organization_users, fn organization_user ->
        organization_user.organization_id == query.organization_id
      end)

    if organization_user.permissions.super_admin or query.user_id == user.id do
      Repo.delete(query)
    else
      {:error, :not_allowed_to_delete_query}
    end
  end
end
