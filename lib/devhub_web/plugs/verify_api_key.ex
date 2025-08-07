defmodule DevhubWeb.Plugs.VerifyApiKey do
  @moduledoc false

  import Plug.Conn

  alias Devhub.ApiKeys

  def init(opts), do: opts

  def call(conn, _params) do
    with [token] <- get_req_header(conn, "x-api-key"),
         {:ok, api_key} <- ApiKeys.verify(token),
         true <- route_allowed?(conn, api_key) do
      conn
      |> assign(:organization_id, api_key.organization_id)
      |> assign(:api_key, api_key)
    else
      _error ->
        conn
        |> send_resp(401, "")
        |> halt()
    end
  end

  defp route_allowed?(conn, api_key) do
    full_access = Enum.member?(api_key.permissions, :full_access)

    case conn.path_info do
      ["api", "v1", "coverbot" | _rest] ->
        full_access or Enum.member?(api_key.permissions, :coverbot)

      ["api", "v1", "querydesk", "databases", "setup"] ->
        full_access or Enum.member?(api_key.permissions, :querydesk_limited)

      ["api", "v1", "querydesk", "databases", "remove", _api_id] ->
        full_access or Enum.member?(api_key.permissions, :querydesk_limited)

      ["api", "v1", "workflows", _id, "run" | _rest] ->
        full_access or Enum.member?(api_key.permissions, :trigger_workflows)

      _other ->
        full_access
    end
  end
end
