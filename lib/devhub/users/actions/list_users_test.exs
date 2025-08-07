defmodule Devhub.Users.Actions.ListUsersTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users

  test "list_users/1" do
    organization = insert(:organization)

    %{id: github_user_id} =
      insert(:github_user, organization: organization, username: "michaelst")

    %{id: linear_user_id} =
      insert(:linear_user, organization: organization, external_id: "1234", name: "Michael")

    %{id: organization_user_id} =
      insert(:organization_user,
        organization: organization,
        inserted_at: ~U[2023-10-01 00:00:00Z],
        updated_at: ~U[2023-12-01 00:00:00Z],
        github_user_id: github_user_id,
        linear_user_id: linear_user_id
      )

    %{id: team_id} = insert(:team, name: "pdq", organization: organization)

    insert(:team_member,
      organization_user_id: organization_user_id,
      team_id: team_id,
      inserted_at: ~U[2024-01-01 00:00:00Z],
      updated_at: ~U[2024-01-02 00:00:00Z]
    )

    assert [
             %{
               email: nil,
               github_user_id: ^github_user_id,
               github_username: "michaelst",
               id: nil,
               linear_user_id: ^linear_user_id,
               linear_username: "Michael",
               name: "Michael",
               organization_user: _organization_user,
               picture: nil,
               team_ids: ^team_id,
               teams: "pdq",
               license_ref: ":",
               pending: nil
             }
           ] =
             Users.list_users(organization.id)
  end
end
