defmodule Devhub.Users.Actions.MergeTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "user already exists" do
    organization = insert(:organization)

    %{id: linear_user_id} = insert(:linear_user, organization: organization)
    %{id: github_user_id} = insert(:github_user, organization: organization)

    %{id: org_user_id} =
      organization_user = insert(:organization_user, organization: organization, linear_user_id: linear_user_id)

    organization_user_to_merge = insert(:organization_user, organization: organization, github_user_id: github_user_id)

    assert {:ok,
            %{
              id: ^org_user_id,
              linear_user_id: ^linear_user_id,
              github_user_id: ^github_user_id
            }} = Users.merge(organization_user, organization_user_to_merge)
  end
end
