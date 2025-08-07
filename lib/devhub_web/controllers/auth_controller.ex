defmodule DevhubWeb.AuthController do
  use DevhubWeb, :controller

  alias Devhub.Users

  require Logger

  def login(conn, %{"token" => token} = params) do
    return_to = params["return_to"] || get_session(conn, :return_to) || ~p"/"

    {:ok, user} = Users.login(token, conn.assigns.organization)

    conn
    |> put_session(:user_id, user.id)
    |> put_session(:return_to, return_to)
    |> configure_session(renew: true)
    |> handle_successful_login()
  rescue
    _error ->
      redirect(conn, to: ~p"/")
  end

  def mfa(conn, _params) do
    user_id = get_session(conn, :user_id)
    passkeys = Users.get_passkeys(user_id)

    if Enum.empty?(passkeys) do
      {:ok, user} = Users.get_by(id: user_id)
      challenge = Wax.new_registration_challenge()

      conn
      |> put_session(:registration_challenge, challenge)
      |> render(:setup_mfa,
        challenge: Base.encode64(challenge.bytes),
        attestation: challenge.attestation,
        userId: user.id,
        displayName: user.email,
        rpId: challenge.rp_id,
        layout: false
      )
    else
      allow_credentials = Enum.map(passkeys, &{&1.raw_id, :erlang.binary_to_term(&1.public_key)})
      challenge = Wax.new_authentication_challenge(allow_credentials: allow_credentials)

      conn
      |> put_session(:authentication_challenge, challenge)
      |> render(:mfa,
        challenge: Base.encode64(challenge.bytes),
        cred_ids: Enum.map(passkeys, & &1.raw_id),
        layout: false
      )
    end
  end

  def setup_mfa(conn, params) do
    user_id = get_session(conn, :user_id)
    {:ok, user} = Users.get_by(id: user_id)

    case register_passkey(conn, params, user) do
      {:ok, _passkey} ->
        conn
        |> put_session(:mfa_at, DateTime.utc_now())
        |> handle_successful_login()

      _error ->
        redirect(conn, to: ~p"/auth/mfa")
    end
  end

  def verify_mfa(conn, params) do
    challenge = get_session(conn, :authentication_challenge)
    user_id = get_session(conn, :user_id)
    passkeys = Users.get_passkeys(user_id)
    allow_credentials = Enum.map(passkeys, &{&1.raw_id, :erlang.binary_to_term(&1.public_key)})

    case Users.authenticate_passkey(params, challenge, allow_credentials) do
      :ok ->
        conn
        |> put_session(:mfa_at, DateTime.utc_now())
        |> handle_successful_login()

      :error ->
        redirect(conn, to: ~p"/auth/mfa")
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end

  def oidc_request(conn, _params) do
    {:ok, _oidc, config} = Users.get_oidc_config(organization_id: conn.assigns.organization.id)

    {:ok, uri} = OpenIDConnect.authorization_uri(config)

    redirect(conn, external: uri)
  end

  def oidc_callback(conn, params) do
    {:ok, _oidc, config} = Users.get_oidc_config(organization_id: conn.assigns.organization.id)

    with {:ok, tokens} <-
           OpenIDConnect.fetch_tokens(config, %{code: params["code"]}),
         {:ok, %{"sub" => external_id, "aud" => provider} = claims} <-
           OpenIDConnect.verify(config, tokens["id_token"]),
         {:ok, info} <- OpenIDConnect.fetch_userinfo(config, tokens["access_token"]),
         {:ok, user} <-
           Users.login(
             %{
               name: info["name"],
               email: info["email"],
               provider: provider,
               external_id: external_id,
               roles: claims["roles"] || []
             },
             conn.assigns.organization
           ) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> handle_successful_login()
    else
      _error -> redirect(conn, to: ~p"/")
    end
  end

  if Application.compile_env(:devhub, :dev_routes) do
    def login_as(conn, %{"id" => id}) do
      conn
      |> put_session(:user_id, id)
      |> configure_session(renew: true)
      |> handle_successful_login()
    end
  end

  defp handle_successful_login(conn) do
    return_to = get_session(conn, :return_to) || ~p"/"

    redirect(conn, to: return_to)
  end
end
