defmodule Devhub.Dashboard.Actions.ListDashboards do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback list_dashboards(OrganizationUser.t()) :: [%Dashboard{}]
  def list_dashboards(organization_user) do
    super_admin? = organization_user.permissions.super_admin

    query =
      from d in Dashboard,
        left_join: p in assoc(d, :permissions),
        left_join: r in assoc(p, :role),
        left_join: rou in assoc(r, :organization_users),
        where: d.organization_id == ^organization_user.organization_id,
        where:
          ^super_admin? or not d.restricted_access or
            p.organization_user_id == ^organization_user.id or rou.id == ^organization_user.id,
        distinct: true

    Repo.all(query)
  end
end
