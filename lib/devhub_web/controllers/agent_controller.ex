defmodule DevhubWeb.AgentController do
  use DevhubWeb, :controller

  alias Devhub.Agents

  def socket(conn, params) do
    case Phoenix.Token.verify(DevhubWeb.Endpoint, "agent token", params["token"], max_age: :infinity) do
      {:ok, agent_id} ->
        WebSockAdapter.upgrade(conn, DevhubWeb.AgentConnection, %{agent_id: agent_id}, timeout: 60_000)

      _error ->
        send_resp(conn, 401, "unauthorized")
    end
  end

  def config(conn, %{"id" => agent_id}) do
    with %{super_admin: true} <- conn.assigns.organization_user.permissions,
         {:ok, agent} <- Agents.get(id: agent_id, organization_id: conn.assigns.organization.id) do
      json =
        Jason.encode!(%{
          agent_id: agent.id,
          endpoint: DevhubWeb.Endpoint.url(),
          token: Phoenix.Token.sign(DevhubWeb.Endpoint, "agent token", agent.id)
        })

      conn
      |> put_resp_content_type("application/json")
      |> put_resp_header(
        "content-disposition",
        ~s(attachment; filename="config.json")
      )
      |> send_resp(200, json)
    else
      _error ->
        send_resp(conn, 404, "not found")
    end
  end
end
