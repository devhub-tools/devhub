defmodule Devhub.Users.Actions.Login do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Licensing.Client
  alias Devhub.Repo
  alias Devhub.Users
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Users.User
  alias DevhubPrivate.Licensing
  alias DevhubPrivate.Permissions

  @callback login(String.t() | map(), Organization.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def login(token, organization) when is_binary(token) do
    {:ok, details} = Client.verify_user(token, organization)

    params = %{
      name: details["name"],
      email: details["email"],
      picture: details["picture"],
      provider: details["provider"],
      external_id: details["external_id"]
    }

    login(params, organization)
  end

  def login(params, organization) when is_map(params) do
    case Users.get_by(email: params.email) do
      {:ok, user} ->
        user
        |> maybe_reassign_invite_license(params)
        |> maybe_assign_roles(params, organization)
        |> Users.update_user(params)

      # if the user already exists we will do an upsert which will create a new user if the provider/external_id is different
      _other ->
        with {:ok, user} <- Users.upsert_user(params),
             {:ok, organization_user} <- upsert_organization_user(organization, user.id) do
          user = maybe_assign_roles(%{user | organization_users: [organization_user]}, params, organization)
          {:ok, user}
        end
    end
  end

  if Code.ensure_loaded?(Permissions) do
    defp maybe_assign_roles(user, %{roles: roles}, organization) when is_list(roles) do
      [organization_user] = user.organization_users
      existing_roles = organization_user.roles |> Enum.filter(& &1.managed) |> Enum.map(&String.downcase(&1.name))
      # we set this as a separate variable because we need original case for saving to the db but downcase for comparison
      downcased_roles = Enum.map(roles, &String.downcase(&1))

      roles_to_remove =
        existing_roles
        |> Enum.reject(&Enum.member?(downcased_roles, &1))
        |> Enum.map(fn role_name ->
          with {:ok, role} <- Permissions.get_role(organization_id: organization.id, name: role_name) do
            Permissions.remove_role(organization_user.id, role.id)
            role.id
          end
        end)

      roles_to_add =
        roles
        |> Enum.reject(&Enum.member?(existing_roles, String.downcase(&1)))
        |> Enum.map(fn role_name ->
          with {:ok, role} <- Permissions.create_role(%{name: role_name, managed: true}, organization) do
            {:ok, _org_user_role} = Permissions.add_role(organization_user.id, role.id)
            role
          end
        end)

      roles =
        organization_user.roles
        |> Enum.filter(&(&1.id not in roles_to_remove))
        |> Enum.concat(roles_to_add)

      %{user | organization_users: [%{organization_user | roles: roles}]}
    end
  end

  defp maybe_assign_roles(user, _params, _organization) do
    user
  end

  defp upsert_organization_user(organization, user_id) do
    %{
      organization_id: organization.id,
      user_id: user_id,
      pending: not is_nil(organization.license),
      # if there is no license that means they haven't started onboarding yet
      # so it allows a user during setup to get in
      permissions: %{super_admin: is_nil(organization.license)},
      roles: []
    }
    |> OrganizationUser.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:user_id]},
      conflict_target: [:organization_id, :user_id],
      returning: true
    )
  end

  if Code.ensure_loaded?(Licensing) do
    defp maybe_reassign_invite_license(%{provider: "invite"} = user, params) do
      %{organization_users: [organization_user]} = user

      # revoke the invite license
      Licensing.unassign_seat(%{organization_user | user: user})

      # assign a license to the logged in user
      Licensing.assign_seat(%{
        organization_user
        | user: %{user | provider: params.provider, external_id: params.external_id}
      })

      user
    end
  end

  defp maybe_reassign_invite_license(user, _params) do
    user
  end
end
