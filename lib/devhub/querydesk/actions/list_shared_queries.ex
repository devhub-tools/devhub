defmodule Devhub.QueryDesk.Actions.ListSharedQueries do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Permissions
  alias Devhub.QueryDesk.Schemas.SharedQuery
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback list_shared_queries(OrganizationUser.t()) :: [SharedQuery.t()]
  def list_shared_queries(organization_user) do
    query =
      from sq in SharedQuery,
        left_join: p in assoc(sq, :permissions),
        left_join: ou in assoc(p, :organization_user),
        left_join: u in assoc(ou, :user),
        left_join: r in assoc(p, :role),
        where: is_nil(sq.expires_at) or sq.expires_at > ^DateTime.utc_now(),
        where: sq.organization_id == ^organization_user.organization_id,
        order_by: [desc: sq.updated_at],
        preload: [
          :database,
          :created_by_user,
          permissions: {p, [organization_user: {ou, [user: u]}, role: r]}
        ]

    query
    |> Repo.all()
    |> Enum.filter(fn shared_query ->
      not shared_query.restricted_access or
        shared_query.created_by_user_id == organization_user.user_id or
        Permissions.can?(:read, shared_query, organization_user)
    end)
  end
end
