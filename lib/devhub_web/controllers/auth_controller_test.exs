defmodule DevhubWeb.AuthControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Users.User
  alias Tesla.Adapter.Finch

  test "GET /auth/callback", %{organization: %{installation_id: installation_id}} do
    params = %{
      "name" => "Michael St Clair",
      "email" => "michael@devhub.tools",
      "picture" => "https://avatars.githubusercontent.com/u/1234567?v=4",
      "provider" => "github",
      "external_id" => "1234567"
    }

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: "https://licensing.devhub.cloud/installations/verify-user",
                              body: body,
                              headers: [
                                {"traceparent", _traceparent},
                                {"content-type", "application/json"}
                              ]
                            },
                            _opts ->
      assert %{
               "token" => "token",
               "signature" => _signature,
               "installation_id" => ^installation_id
             } = Jason.decode!(body)

      TeslaHelper.response(body: params)
    end)

    response = get(Phoenix.ConnTest.build_conn(), "/auth/callback?token=token")

    user_id = get_session(response, :user_id)

    assert %{email: "michael@devhub.tools"} = Devhub.Repo.get(User, user_id)

    assert redirected_to(response) == "/"
  end

  test "GET /auth/callback - invalid token" do
    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: "https://licensing.devhub.cloud/installations/verify-user"
                            },
                            _opts ->
      TeslaHelper.response(status: 403)
    end)

    response = get(Phoenix.ConnTest.build_conn(), "/auth/callback?token=token")

    refute get_session(response, :user_id)

    assert redirected_to(response) == "/"
  end

  describe "GET /auth/mfa" do
    test "passkey already setup", %{conn: conn, user: user} do
      passkey = insert(:passkey, user: user)

      response =
        conn
        |> get(~p"/auth/mfa")
        |> html_response(200)

      assert response =~ "Verify your MFA"
      assert response =~ passkey.raw_id
    end

    test "passkey not setup", %{conn: conn} do
      response =
        conn
        |> get(~p"/auth/mfa")
        |> html_response(200)

      assert response =~ "Setup MFA to continue"
    end
  end

  describe "POST /auth/mfa" do
    test "success", %{conn: conn, user: user} do
      passkey = insert(:passkey, user: user)

      allow_credentials = [{passkey.raw_id, :erlang.binary_to_term(passkey.public_key)}]

      challenge =
        [allow_credentials: allow_credentials]
        |> Wax.new_authentication_challenge()
        |> Map.put(
          :bytes,
          <<24, 117, 127, 248, 106, 176, 81, 166, 136, 189, 216, 13, 253, 13, 54, 80, 111, 231, 158, 86, 203, 71, 183,
            141, 131, 148, 55, 105, 245, 20, 162, 188>>
        )

      params = %{
        "authenticatorData" => "SZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2MdAAAAAA==",
        "clientDataJSON" =>
          ~s({"type":"webauthn.get","challenge":"GHV_-GqwUaaIvdgN_Q02UG_nnlbLR7eNg5Q3afUUorw","origin":"http://localhost:4000","crossOrigin":false}),
        "rawId" => "2fomAYPOXkoe32isN3nAuotahwQ=",
        "sig" => "MEUCIQCU17iE5STV9waFu2GAnXl+zOGb3WFxjqpFBVeOhbOGlgIgTd5Ashoa9StHF8JxjBkj1Ysph8Du+qwlKLb6N9gbaSs=",
        "type" => "public-key"
      }

      assert conn
             |> init_test_session(%{authentication_challenge: challenge})
             |> post(~p"/auth/mfa", params)
             |> redirected_to() == "/"
    end

    test "failure", %{conn: conn, user: user} do
      passkey = insert(:passkey, user: user)

      allow_credentials = [{passkey.raw_id, :erlang.binary_to_term(passkey.public_key)}]

      challenge = Wax.new_authentication_challenge(allow_credentials: allow_credentials)

      params = %{
        "authenticatorData" => "SZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2MdAAAAAA==",
        "clientDataJSON" =>
          ~s({"type":"webauthn.get","challenge":"GHV_-GqwUaaIvdgN_Q02UG_nnlbLR7eNg5Q3afUUorw","origin":"http://localhost:4000","crossOrigin":false}),
        "rawId" => "2fomAYPOXkoe32isN3nAuotahwQ=",
        "sig" => "MEUCIQCU17iE5STV9waFu2GAnXl+zOGb3WFxjqpFBVeOhbOGlgIgTd5Ashoa9StHF8JxjBkj1Ysph8Du+qwlKLb6N9gbaSs=",
        "type" => "public-key"
      }

      assert conn
             |> init_test_session(%{authentication_challenge: challenge})
             |> post(~p"/auth/mfa", params)
             |> redirected_to() == "/auth/mfa"
    end
  end

  describe "POST /auth/mfa/setup" do
    test "success", %{conn: conn} do
      challenge =
        Map.put(
          Wax.new_registration_challenge(),
          :bytes,
          <<114, 113, 208, 120, 148, 6, 15, 203, 126, 119, 242, 163, 4, 163, 142, 2, 147, 143, 251, 89, 11, 91, 108, 102,
            228, 170, 76, 0, 110, 171, 153, 81>>
        )

      params = %{
        "attestationObject" =>
          "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYSZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2NdAAAAAPv8MAcVTk7MjAtuAgVX170AFN/DZdnLEeOcKy+YmYw5vK+Mcz0kpQECAyYgASFYIDnPxUHE2D2OxVxMjv9iHf+Yj4uE4FUw9OT+mt3otN8iIlggA5/+84UUHSgqf3IrseTYNoQ9SPMSFMKJDkGfKFDHVF8=",
        "clientDataJSON" =>
          ~s({"type":"webauthn.create","challenge":"cnHQeJQGD8t-d_KjBKOOApOP-1kLW2xm5KpMAG6rmVE","origin":"http://localhost:4000","crossOrigin":false}),
        "rawId" => "38Nl2csR45wrL5iZjDm8r4xzPSQ=",
        "type" => "public-key"
      }

      assert conn
             |> init_test_session(%{registration_challenge: challenge})
             |> post(~p"/auth/mfa/setup", params)
             |> redirected_to() == "/"
    end

    test "failure", %{conn: conn} do
      challenge = Wax.new_registration_challenge()

      params = %{
        "attestationObject" =>
          "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYSZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2NdAAAAAPv8MAcVTk7MjAtuAgVX170AFN/DZdnLEeOcKy+YmYw5vK+Mcz0kpQECAyYgASFYIDnPxUHE2D2OxVxMjv9iHf+Yj4uE4FUw9OT+mt3otN8iIlggA5/+84UUHSgqf3IrseTYNoQ9SPMSFMKJDkGfKFDHVF8=",
        "clientDataJSON" =>
          ~s({"type":"webauthn.create","challenge":"cnHQeJQGD8t-d_KjBKOOApOP-1kLW2xm5KpMAG6rmVE","origin":"http://localhost:4000","crossOrigin":false}),
        "rawId" => "38Nl2csR45wrL5iZjDm8r4xzPSQ=",
        "type" => "public-key"
      }

      assert conn
             |> init_test_session(%{registration_challenge: challenge})
             |> post(~p"/auth/mfa/setup", params)
             |> redirected_to() == "/auth/mfa"
    end
  end

  test "GET /auth/oidc", %{organization: organization} do
    insert(:oidc, organization: organization)

    uri =
      "https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email&client_id=7066f679-348c-4ec0-842d-8a9e6b2c9134&redirect_uri=http%3A%2F%2Flocalhost%3A4002%2Fauth%2Foidc%2Fcallback&response_type=code"

    expect(OpenIDConnect, :authorization_uri, fn _config ->
      {:ok, uri}
    end)

    assert Phoenix.ConnTest.build_conn()
           |> init_test_session(%{})
           |> Plug.Conn.assign(:organization, organization)
           |> get("/auth/oidc")
           |> redirected_to() == uri
  end

  test "GET /auth/oidc/callback", %{organization: organization} do
    insert(:oidc, organization: organization)

    OpenIDConnect
    |> expect(:fetch_tokens, fn _config, %{code: "123456"} ->
      {:ok, %{"id_token" => "id_token", "access_token" => "access_token"}}
    end)
    |> expect(:verify, fn _config, "id_token" ->
      {:ok, %{"sub" => "external_id", "aud" => "provider"}}
    end)
    |> expect(:fetch_userinfo, fn _config, "access_token" ->
      {:ok, %{"name" => "Michael St Clair", "email" => "michael@devhub.tools"}}
    end)

    response =
      Phoenix.ConnTest.build_conn()
      |> init_test_session(%{})
      |> Plug.Conn.assign(:organization, organization)
      |> get("/auth/oidc/callback?code=123456")

    user_id = get_session(response, :user_id)

    assert {:ok,
            %{
              email: "michael@devhub.tools"
            }} = Devhub.Users.get_by(id: user_id)

    assert redirected_to(response) == "/"
  end

  test "GET /auth/oidc/callback - invalid", %{organization: organization} do
    insert(:oidc, organization: organization)

    expect(OpenIDConnect, :fetch_tokens, fn _config, %{code: "123456"} ->
      {:error, :invalid}
    end)

    response =
      Phoenix.ConnTest.build_conn()
      |> init_test_session(%{})
      |> Plug.Conn.assign(:organization, organization)
      |> get("/auth/oidc/callback?code=123456")

    refute get_session(response, :user_id)

    assert redirected_to(response) == "/"
  end

  test "GET /auth/logout", %{conn: conn} do
    assert conn
           |> get(~p"/auth/logout")
           |> redirected_to() == "/"
  end
end
