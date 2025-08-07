defmodule DevhubWeb.Middleware.EnsureAuthenticated.Plug do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn

  alias Devhub.Users

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    email_auth_header = Application.get_env(:devhub, :auth_email_header)
    groups_auth_header = Application.get_env(:devhub, :auth_groups_header)

    email = email_auth_header && get_req_header(conn, String.downcase(email_auth_header))

    groups =
      with true <- is_binary(groups_auth_header),
           [groups_string] <- get_req_header(conn, String.downcase(groups_auth_header)) do
        String.split(groups_string || "", ",")
      else
        _invalid -> nil
      end

    if not is_nil(email_auth_header) do
      Logger.info("Logging in with email auth header \"#{email_auth_header}: #{email}\"")
    end

    with {:ok, %{organization_users: [organization_user]} = user} <- get_user(conn, email, groups),
         conn = put_session(conn, :user_id, user.id),
         :ok <- check_mfa(conn, user) do
      conn
      |> assign(:user, user)
      |> assign(:organization_user, organization_user)
      |> assign(:permissions, organization_user.permissions)
    else
      {:error, :mfa_required} ->
        conn
        |> put_session(:return_to, current_path(conn))
        |> redirect(to: "/auth/mfa")
        |> halt()

      _error ->
        not_authenticated(conn)
    end
  end

  def get_user(conn, [email], groups) when is_binary(email) do
    Users.login(%{email: email, provider: "header", external_id: email, roles: groups}, conn.assigns.organization)
  end

  def get_user(conn, _not_header_auth, _groups) do
    with user_id when is_binary(user_id) <- get_session(conn, :user_id) do
      Users.get_by(id: user_id)
    end
  end

  defp check_mfa(conn, user) do
    mfa_at = get_session(conn, :mfa_at)
    mfa_required? = conn.assigns.organization.mfa_required

    cond do
      # if they have already verified mfa
      not is_nil(mfa_at) -> :ok
      # if they have not setup mfa and it is not required
      Enum.empty?(Users.get_passkeys(user)) and not mfa_required? -> :ok
      true -> {:error, :mfa_required}
    end
  end

  defp not_authenticated(conn) do
    with nil <- Application.get_env(:devhub, :auth_email_header),
         {:error, :oidc_config_not_found} <- Users.get_oidc_config(organization_id: conn.assigns.organization.id) do
      conn
      |> put_session(:return_to, current_path(conn))
      |> redirect(
        external:
          Application.get_env(:devhub, :login_url) <> "?installation_id=#{conn.assigns.organization.installation_id}"
      )
      |> halt()
    else
      {:ok, _oidc, config} ->
        {:ok, uri} = OpenIDConnect.authorization_uri(config)

        conn
        |> put_session(:return_to, current_path(conn))
        |> redirect(external: uri)
        |> halt()

      _header ->
        conn |> redirect(to: "/not-authenticated") |> halt()
    end
  end
end

defmodule DevhubWeb.Middleware.EnsureAuthenticated.Hook do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Users

  def on_mount(:default, _params, session, socket) do
    {:ok, %{organization_users: [organization_user]} = user} = Users.get_by(id: session["user_id"])

    socket
    |> assign(
      organization_id: organization_user.organization_id,
      user: user,
      organization_user: organization_user,
      permissions: organization_user.permissions,
      mfa_enabled?: not is_nil(session["mfa_at"])
    )
    |> cont()
  end
end
