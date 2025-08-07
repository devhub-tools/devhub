defmodule Devhub.Users do
  @moduledoc false
  @behaviour Devhub.Users.Actions.AddToTeam
  @behaviour Devhub.Users.Actions.AuthenticatePasskey
  @behaviour Devhub.Users.Actions.CreateOrganizationUser
  @behaviour Devhub.Users.Actions.CreateTeam
  @behaviour Devhub.Users.Actions.DeleteTeam
  @behaviour Devhub.Users.Actions.GenerateProxyPassword
  @behaviour Devhub.Users.Actions.GetBy
  @behaviour Devhub.Users.Actions.GetOidcConfig
  @behaviour Devhub.Users.Actions.GetOrganization
  @behaviour Devhub.Users.Actions.GetOrganizationUser
  @behaviour Devhub.Users.Actions.GetPasskeys
  @behaviour Devhub.Users.Actions.GetTeam
  @behaviour Devhub.Users.Actions.InsertOrUpdateOidc
  @behaviour Devhub.Users.Actions.InviteUser
  @behaviour Devhub.Users.Actions.ListOrganizationUsers
  @behaviour Devhub.Users.Actions.ListTeams
  @behaviour Devhub.Users.Actions.ListUsers
  @behaviour Devhub.Users.Actions.Login
  @behaviour Devhub.Users.Actions.Merge
  @behaviour Devhub.Users.Actions.RegisterPasskey
  @behaviour Devhub.Users.Actions.RemoveFromTeam
  @behaviour Devhub.Users.Actions.RemovePasskey
  @behaviour Devhub.Users.Actions.UpdateOrganization
  @behaviour Devhub.Users.Actions.UpdateOrganizationUser
  @behaviour Devhub.Users.Actions.UpdateTeam
  @behaviour Devhub.Users.Actions.UpdateUser
  @behaviour Devhub.Users.Actions.UpsertUser

  alias Devhub.Users.Actions

  ### Users
  @impl Actions.ListUsers
  defdelegate list_users(organization_id), to: Actions.ListUsers

  @impl Actions.GetBy
  defdelegate get_by(by), to: Actions.GetBy

  @impl Actions.InviteUser
  defdelegate invite_user(name, email), to: Actions.InviteUser

  @impl Actions.InviteUser
  defdelegate invite_user(organization_user, name, email), to: Actions.InviteUser

  @impl Actions.GetOrganizationUser
  defdelegate get_organization_user(by), to: Actions.GetOrganizationUser

  @impl Actions.Login
  defdelegate login(params, organization_id), to: Actions.Login

  @impl Actions.UpsertUser
  defdelegate upsert_user(params), to: Actions.UpsertUser

  @impl Actions.ListOrganizationUsers
  defdelegate list_organization_users(organization_id), to: Actions.ListOrganizationUsers

  @impl Actions.Merge
  defdelegate merge(organization_user, organization_user_to_merge), to: Actions.Merge

  @impl Actions.UpdateUser
  defdelegate update_user(user, params), to: Actions.UpdateUser

  @impl Actions.GenerateProxyPassword
  defdelegate generate_proxy_password(user, duration), to: Actions.GenerateProxyPassword

  ### Organizations
  @impl Actions.GetOrganization
  defdelegate get_organization(), to: Actions.GetOrganization

  @impl Actions.GetOrganization
  defdelegate get_organization(by), to: Actions.GetOrganization

  @impl Actions.UpdateOrganization
  defdelegate update_organization(organization, attrs), to: Actions.UpdateOrganization

  @impl Actions.CreateOrganizationUser
  defdelegate create_organization_user(attrs), to: Actions.CreateOrganizationUser

  @impl Actions.UpdateOrganizationUser
  defdelegate update_organization_user(organization_user, attrs), to: Actions.UpdateOrganizationUser

  ### Teams
  @impl Actions.ListTeams
  defdelegate list_teams(organization_id), to: Actions.ListTeams

  @impl Actions.GetTeam
  defdelegate get_team(id), to: Actions.GetTeam

  @impl Actions.CreateTeam
  defdelegate create_team(name, organization), to: Actions.CreateTeam

  @impl Actions.UpdateTeam
  defdelegate update_team(team, params), to: Actions.UpdateTeam

  @impl Actions.DeleteTeam
  defdelegate delete_team(team), to: Actions.DeleteTeam

  @impl Actions.AddToTeam
  defdelegate add_to_team(organization_user_id, team_id), to: Actions.AddToTeam

  @impl Actions.RemoveFromTeam
  defdelegate remove_from_team(organization_user_id, team_id), to: Actions.RemoveFromTeam

  ### OIDC
  @impl Actions.GetOidcConfig
  defdelegate get_oidc_config(by, active \\ true), to: Actions.GetOidcConfig

  @impl Actions.InsertOrUpdateOidc
  defdelegate insert_or_update_oidc(oidc, attrs), to: Actions.InsertOrUpdateOidc

  ### MFA ###

  @impl Actions.RegisterPasskey
  defdelegate register_passkey(user, params), to: Actions.RegisterPasskey

  @impl Actions.AuthenticatePasskey
  defdelegate authenticate_passkey(params, challenge, allow_credentials), to: Actions.AuthenticatePasskey

  @impl Actions.GetPasskeys
  defdelegate get_passkeys(user), to: Actions.GetPasskeys

  @impl Actions.RemovePasskey
  defdelegate remove_passkey(user, passkey), to: Actions.RemovePasskey
end
