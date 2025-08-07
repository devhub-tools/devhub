defmodule DevhubWeb.GitHubControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Users
  alias Tesla.Adapter.Finch

  test "github setup flow", %{conn: conn, organization: organization} do
    organization_id = organization.id
    installation_id = Ecto.UUID.generate()

    Users.update_organization(organization, %{onboarding: %{done: false}})

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: url
                            },
                            _opts ->
      assert url == "https://api.github.com/app-manifests/123456/conversions"

      TeslaHelper.response(
        body: %{
          "id" => 1,
          "slug" => "devhub-app",
          "client_id" => "client_id",
          "client_secret" => "client_secret",
          "webhook_secret" => "webhook_secret",
          "pem" => "private_key"
        }
      )
    end)

    # success
    assert conn
           |> get(~p"/github/setup-app?code=123456")
           |> html_response(302) =~ "https://github.com/apps/devhub-app/installations/new"

    GitHub
    |> expect(:get_installation, fn ^organization_id, ^installation_id ->
      {:ok, %{"account" => %{"login" => "devhub-tools"}}}
    end)
    |> expect(:import_users, fn _integration -> :ok end)
    |> expect(:import_repositories, fn _integration -> :ok end)

    assert conn
           |> get(~p"/github/setup-installation?installation_id=#{installation_id}")
           |> html_response(302) =~ "/setup"
  end

  test "not super admin", %{organization: organization} do
    Users.update_organization(organization, %{onboarding: %{done: false}})

    user = insert(:user, organization_users: [build(:organization_user, organization: organization)])

    assert Phoenix.ConnTest.build_conn()
           |> Plug.Test.init_test_session(%{})
           |> put_session(:user_id, user.id)
           |> get(~p"/github/setup-app?code=123456")
           |> html_response(302) == "<html><body>You are being <a href=\"/\">redirected</a>.</body></html>"

    assert Phoenix.ConnTest.build_conn()
           |> Plug.Test.init_test_session(%{})
           |> put_session(:user_id, user.id)
           |> get(~p"/github/setup-installation?installation_id=123456")
           |> html_response(302) == "<html><body>You are being <a href=\"/\">redirected</a>.</body></html>"
  end
end
