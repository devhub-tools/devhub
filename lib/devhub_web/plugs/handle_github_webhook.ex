defmodule DevhubWeb.Plugs.HandleGitHubWebhook do
  @moduledoc false
  import Plug.Conn

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Webhook

  def init(opts) do
    opts
  end

  def call(%{request_path: "/webhook/github"} = conn, _opts) do
    {:ok, payload, conn} = read_body(conn)

    with [signature_in_header] <- get_req_header(conn, "x-hub-signature-256"),
         [app_id] <- get_req_header(conn, "x-github-hook-installation-target-id"),
         {:ok, app} <- GitHub.get_app(external_id: app_id),
         true <- verify_signature(payload, app.webhook_secret, signature_in_header) || {:error, :invalid_signature} do
      :ok = Webhook.handle(app, payload)
      conn |> send_resp(200, "OK") |> halt()
    else
      {:error, :github_app_not_found} -> conn |> send_resp(200, "OK") |> halt()
      _error -> conn |> send_resp(403, "Forbidden") |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp verify_signature(payload, secret, signature_in_header) do
    signature =
      "sha256=" <> (:hmac |> :crypto.mac(:sha256, secret, payload) |> Base.encode16(case: :lower))

    Plug.Crypto.secure_compare(signature, signature_in_header)
  end
end
