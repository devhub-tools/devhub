defmodule Devhub.Users.Actions.GetOrganizationUser do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback get_organization_user(Keyword.t()) :: {:ok, OrganizationUser.t()} | {:error, :organization_user_not_found}
  def get_organization_user(by) do
    query =
      from ou in OrganizationUser,
        join: u in assoc(ou, :user),
        join: o in assoc(ou, :organization),
        where: ^by,
        preload: [:roles, user: u, organization: o]

    case Repo.one(query) do
      user when is_struct(user) ->
        {:ok, user}

      _error ->
        {:error, :organization_user_not_found}
    end
  end
end
