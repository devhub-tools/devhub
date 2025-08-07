defmodule Devhub.Users.Actions.Merge do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users
  alias Devhub.Users.Schemas.OrganizationUser

  @callback merge(OrganizationUser.t(), OrganizationUser.t()) :: {:ok, OrganizationUser.t()} | {:error, :cannot_merge}
  def merge(organization_user, organization_user_to_merge) do
    one_with_no_user? = is_nil(organization_user.user_id) or is_nil(organization_user_to_merge.user_id)

    one_with_no_linear_user? =
      is_nil(organization_user.linear_user_id) or is_nil(organization_user_to_merge.linear_user_id)

    one_with_no_github_user? =
      is_nil(organization_user.github_user_id) or is_nil(organization_user_to_merge.github_user_id)

    # can't merge if both org users have one of the three values both set
    if one_with_no_user? and one_with_no_linear_user? and one_with_no_github_user? do
      do_merge(organization_user, organization_user_to_merge)
    else
      {:error, :cannot_merge}
    end
  end

  def do_merge(organization_user, organization_user_to_merge) do
    Repo.transaction(fn ->
      if !is_nil(organization_user_to_merge.id) do
        {:ok, _or_user} = Repo.delete(organization_user_to_merge)
      end

      {:ok, org_user} =
        Users.update_organization_user(organization_user, %{
          github_user_id: organization_user.github_user_id || organization_user_to_merge.github_user_id,
          linear_user_id: organization_user.linear_user_id || organization_user_to_merge.linear_user_id,
          user_id: organization_user.user_id || organization_user_to_merge.user_id
        })

      org_user
    end)
  end
end
