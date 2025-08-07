defmodule Devhub.Users.Actions.InviteUserTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.User

  test "user already exists" do
    %{id: org_user_id} = organization_user = insert(:organization_user, organization: build(:organization))
    email = "#{Ecto.UUID.generate()}@devhub.tools"

    # will invite this user who is from another org
    %{id: user_id} =
      insert(:user,
        email: email,
        provider: "github",
        organization_users: [build(:organization_user, organization: build(:organization))]
      )

    assert {:ok,
            %{
              id: ^org_user_id,
              user_id: ^user_id
            }} = Users.invite_user(organization_user, "Michael", email)
  end

  test "create new user" do
    %{id: org_user_id} = organization_user = insert(:organization_user, organization: build(:organization))
    email = "#{Ecto.UUID.generate()}@devhub.tools"

    assert {:ok, %{id: ^org_user_id} = organization_user} = Users.invite_user(organization_user, "Michael", email)
    assert %{user: %User{email: ^email, provider: "invite"}} = Devhub.Repo.preload(organization_user, :user)
  end
end
