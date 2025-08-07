defmodule Devhub.Integrations.Linear.Actions.UsersTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  describe "users/1" do
    test "unfiltered" do
      %{id: org_1_id} = insert(:organization)
      %{id: org_2_id} = insert(:organization)
      %{id: user_1_id} = insert(:linear_user, organization_id: org_1_id)
      %{id: user_2_id} = insert(:linear_user, organization_id: org_1_id)
      insert(:linear_user, organization_id: org_2_id)

      expected_user_ids = Enum.sort([user_1_id, user_2_id])

      assert expected_user_ids ==
               org_1_id |> Linear.users() |> Enum.map(& &1.id) |> Enum.sort()
    end

    test "filtered with team_id" do
      %{id: organization_id} = insert(:organization)
      %{id: user_id} = insert(:linear_user, organization_id: organization_id)
      insert(:linear_user, organization_id: organization_id)

      %{id: team_id} = insert(:team, organization_id: organization_id)

      %{id: org_user_id} =
        insert(:organization_user, organization_id: organization_id, linear_user_id: user_id)

      insert(:team_member, organization_user_id: org_user_id, team_id: team_id)

      assert [%{id: ^user_id}] =
               Linear.users(organization_id, team_id)

      # returns all users when unfiltered
      assert organization_id |> Linear.users() |> length() == 2
    end
  end
end
