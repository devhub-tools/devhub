defmodule Devhub.Users.Actions.ListOrganizationUsersTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "list_organization_users/1" do
    %{id: organization_id} = org = insert(:organization)
    org_2 = insert(:organization)

    %{id: user_1_id} = insert(:user, name: "a", organization_users: [build(:organization_user, organization: org)])
    %{id: user_2_id} = insert(:user, name: "b", organization_users: [build(:organization_user, organization: org)])
    %{id: user_3_id} = insert(:user, name: "c", organization_users: [build(:organization_user, organization: org)])
    insert(:user, organization_users: [build(:organization_user, organization: org_2)])

    assert [%{id: ^user_1_id}, %{id: ^user_2_id}, %{id: ^user_3_id}] = Users.list_organization_users(organization_id)
  end
end
