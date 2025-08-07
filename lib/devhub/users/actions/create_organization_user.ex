defmodule Devhub.Users.Actions.CreateOrganizationUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.Schemas.OrganizationUser

  @callback create_organization_user(map()) :: {:ok, OrganizationUser.t()} | {:error, Ecto.Changeset.t()}
  def create_organization_user(attrs) do
    %OrganizationUser{}
    |> OrganizationUser.changeset(attrs)
    |> Repo.insert()
  end
end
