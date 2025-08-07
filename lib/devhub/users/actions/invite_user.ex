defmodule Devhub.Users.Actions.InviteUser do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Users.Actions.UpsertUser

  alias Devhub.Users
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.Schemas.OrganizationUser

  @callback invite_user(Organization.t(), String.t()) ::
              {:ok, OrganizationUser.t()} | {:error, Ecto.Changeset.t()}
  @callback invite_user(OrganizationUser.t(), String.t(), String.t()) ::
              {:ok, OrganizationUser.t()} | {:error, Ecto.Changeset.t()}
  def invite_user(%Organization{} = organization, email) do
    {:ok, organization_user} =
      Users.create_organization_user(%{organization_id: organization.id, permissions: %{}})

    {:ok, user} =
      email
      |> lookup_user()
      |> maybe_upsert_user(nil, email)

    Users.update_organization_user(organization_user, %{user_id: user.id})
  end

  def invite_user(organization_user, name, email) do
    {:ok, user} =
      email
      |> lookup_user()
      |> maybe_upsert_user(name, email)

    Users.update_organization_user(organization_user, %{user_id: user.id})
  end

  defp lookup_user(email) do
    Users.get_by(email: email)
  end

  defp maybe_upsert_user({:ok, user}, _name, _email), do: {:ok, user}

  defp maybe_upsert_user(_not_found, name, email),
    do: upsert_user(%{name: name, email: email, provider: "invite", external_id: email})
end
