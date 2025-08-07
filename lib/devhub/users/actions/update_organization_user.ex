defmodule Devhub.Users.Actions.UpdateOrganizationUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback update_organization_user(OrganizationUser.t(), map()) ::
              {:ok, OrganizationUser.t()} | {:error, Ecto.Changeset.t()}
  def update_organization_user(organization_user, attrs) do
    organization_user
    |> OrganizationUser.changeset(attrs)
    |> Repo.update()
  end
end
