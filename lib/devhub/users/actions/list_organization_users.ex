defmodule Devhub.Users.Actions.ListOrganizationUsers do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Users.User

  @callback list_organization_users(String.t()) :: [User.t()]
  def list_organization_users(organization_id) do
    query =
      from u in User,
        left_join: ou in assoc(u, :organization_users),
        preload: [organization_users: ou],
        where: ou.organization_id == ^organization_id

    Repo.all(query)
  end
end
