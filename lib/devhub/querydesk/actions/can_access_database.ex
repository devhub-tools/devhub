defmodule Devhub.QueryDesk.Actions.CanAccessDatabase do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Permissions
  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Users.Schemas.OrganizationUser

  @callback can_access_database?(Database.t(), OrganizationUser.t()) :: boolean()
  def can_access_database?(database, organization_user) do
    cond do
      database.organization_id != organization_user.organization_id -> false
      not database.restrict_access -> true
      Permissions.can?(:write, database, organization_user) -> true
      Permissions.can?(:approve, database, organization_user) -> true
      true -> false
    end
  end
end
