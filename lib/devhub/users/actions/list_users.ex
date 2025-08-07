defmodule Devhub.Users.Actions.ListUsers do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback list_users(String.t()) :: [map()]
  def list_users(organization_id) do
    query =
      from ou in OrganizationUser,
        left_join: u in assoc(ou, :user),
        full_join: gu in assoc(ou, :github_user),
        full_join: lu in assoc(ou, :linear_user),
        left_join: t in assoc(ou, :teams),
        left_join: r in assoc(ou, :roles),
        left_join: pk in assoc(u, :passkeys),
        where:
          ou.organization_id == ^organization_id or gu.organization_id == ^organization_id or
            lu.organization_id == ^organization_id,
        select: %{
          id: u.id,
          name: fragment("coalesce(?, ?, ?)", u.name, lu.name, gu.username),
          email: u.email,
          license_ref: fragment("CONCAT(?, ':', ?)", u.provider, u.external_id),
          pending: u.provider == "invite",
          picture: u.picture,
          github_user_id: gu.id,
          github_username: gu.username,
          organization_user: ou,
          linear_user_id: lu.id,
          linear_username: lu.name,
          teams: fragment("STRING_AGG(DISTINCT ?, ', ')", t.name),
          team_ids: fragment("COALESCE(STRING_AGG(DISTINCT ?, ','), '')", t.id),
          roles: fragment("STRING_AGG(DISTINCT ?, ', ')", r.name),
          role_ids: fragment("COALESCE(STRING_AGG(DISTINCT ?, ','), '')", r.id),
          passkeys: count(pk.id)
        },
        group_by: [u.id, u.name, u.email, u.picture, gu.id, gu.username, ou.id, lu.id, lu.name],
        order_by: [desc: is_nil(ou.archived_at), asc: fragment("lower(coalesce(?, ?, ?))", u.name, lu.name, gu.username)]

    Repo.all(query)
  end
end
