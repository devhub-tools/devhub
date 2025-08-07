defmodule DevhubWeb.Middleware.EnsureAuthenticatedTest do
  # sets global env so has to be sync
  use DevhubWeb.ConnCase, async: false

  alias DevhubWeb.Middleware.EnsureAuthenticated

  setup do
    Application.put_env(:devhub, :auth_email_header, nil)
    Application.put_env(:devhub, :auth_groups_header, nil)

    :ok
  end

  test "assigns user if logged in", %{conn: conn, user: %{id: id}} do
    assert %{assigns: %{user: %{id: ^id}}} = EnsureAuthenticated.Plug.call(conn, %{})
  end

  test "redirects to login page when user is not authenticated", %{organization: organization} do
    assert Phoenix.ConnTest.build_conn()
           |> init_test_session(%{})
           |> Plug.Conn.assign(:organization, organization)
           |> EnsureAuthenticated.Plug.call(%{})
           |> redirected_to() == "https://auth.devhub.cloud/login?installation_id=#{organization.installation_id}"
  end

  test "redirects to oidc if configured and not authenticated", %{organization: organization} do
    insert(:oidc, organization: organization)

    uri =
      "https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email&client_id=7066f679-348c-4ec0-842d-8a9e6b2c9134&redirect_uri=http%3A%2F%2Flocalhost%3A4002%2Fauth%2Foidc%2Fcallback&response_type=code"

    expect(OpenIDConnect, :authorization_uri, fn _config ->
      {:ok, uri}
    end)

    assert Phoenix.ConnTest.build_conn()
           |> init_test_session(%{})
           |> Plug.Conn.assign(:organization, organization)
           |> EnsureAuthenticated.Plug.call(%{})
           |> redirected_to() == uri
  end

  test "passes email from header", %{organization: organization} do
    Application.put_env(:devhub, :auth_email_header, "x-forwarded-email")

    assert %{assigns: %{user: %{id: id}}} =
             Phoenix.ConnTest.build_conn()
             |> put_req_header("x-forwarded-email", "michael@devhub.tools")
             |> init_test_session(%{})
             |> Plug.Conn.assign(:organization, organization)
             |> EnsureAuthenticated.Plug.call(%{})

    assert {:ok,
            %{
              email: "michael@devhub.tools"
            }} = Devhub.Users.get_by(id: id)
  end

  test "redirects to not authenticated if using header auth and not authenticated", %{organization: organization} do
    Application.put_env(:devhub, :auth_email_header, "x-auth-email")

    assert Phoenix.ConnTest.build_conn()
           |> init_test_session(%{})
           |> Plug.Conn.assign(:organization, organization)
           |> EnsureAuthenticated.Plug.call(%{})
           |> redirected_to() == "/not-authenticated"
  end

  test "doesn't require mfa if user has already verified", %{conn: conn, user: %{id: id}, organization: organization} do
    assert %{assigns: %{user: %{id: ^id}}} =
             conn
             |> init_test_session(%{"mfa_at" => DateTime.utc_now()})
             |> Plug.Conn.assign(:organization, %{organization | mfa_required: true})
             |> EnsureAuthenticated.Plug.call(%{})
  end

  test "requires mfa if user hasn't verified", %{conn: conn, organization: organization} do
    assert conn
           |> Plug.Conn.assign(:organization, %{organization | mfa_required: true})
           |> EnsureAuthenticated.Plug.call(%{})
           |> redirected_to() == "/auth/mfa"
  end
end
