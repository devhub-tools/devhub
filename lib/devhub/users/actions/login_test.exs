defmodule Devhub.Users.Actions.LoginTest do
  use Devhub.DataCase, async: true

  alias Devhub.Users
  alias Devhub.Users.User

  test "new account signup" do
    organization = insert(:organization)

    params = %{
      name: "michael",
      email: "#{Ecto.UUID.generate()}@devhub.tools",
      external_id: "a1dfdfd3",
      provider: "github"
    }

    assert {:ok,
            %User{
              name: "michael",
              external_id: "a1dfdfd3",
              provider: "github"
            }} = Users.login(params, organization)
  end

  test "handles error" do
    organization = insert(:organization)
    # trigger duplicate error
    user = insert(:user, provider: "google")

    params = %{
      name: "michael",
      email: user.email,
      external_id: Ecto.UUID.generate(),
      provider: "github"
    }

    assert {:error,
            %Ecto.Changeset{
              errors: [
                email: {"has already been taken", [constraint: :unique, constraint_name: "users_email_index"]}
              ]
            }} = Users.login(params, organization)
  end

  test "signup with invite" do
    email = "#{Ecto.UUID.generate()}@devhub.tools"
    organization = insert(:organization)

    %{id: user_id} =
      insert(:user,
        email: email,
        provider: "invite",
        external_id: email,
        organization_users: [build(:organization_user, organization: organization)]
      )

    params = %{
      name: "michael",
      email: email,
      external_id: "a1dfdfd3",
      provider: "github"
    }

    assert {:ok,
            %User{
              id: ^user_id,
              name: "michael",
              email: ^email,
              external_id: "a1dfdfd3",
              provider: "github"
            }} = Users.login(params, organization)
  end

  test "oidc signup" do
    email = "#{Ecto.UUID.generate()}@devhub.tools"
    organization = insert(:organization)

    params = %{
      name: "michael",
      email: email,
      provider: "oidc",
      external_id: Ecto.UUID.generate()
    }

    assert {:ok,
            %User{
              email: ^email,
              provider: "oidc"
            }} = Users.login(params, organization)
  end

  test "oidc login" do
    email = "#{Ecto.UUID.generate()}@devhub.tools"
    organization = insert(:organization)

    %{id: user_id} =
      insert(:user,
        email: email,
        external_id: "a1dfdfd3",
        provider: "oidc",
        organization_users: [build(:organization_user, organization: organization)]
      )

    params = %{
      name: "michael",
      email: email,
      external_id: "a1dfdfd3",
      provider: "oidc"
    }

    assert {:ok,
            %User{
              id: ^user_id,
              email: ^email,
              external_id: "a1dfdfd3",
              provider: "oidc"
            }} = Users.login(params, organization)
  end
end
