defmodule DevhubWeb.Plugs.HandleLinearWebhook do
  @moduledoc false
  import Plug.Conn

  alias Devhub.Integrations

  def init(opts) do
    opts
  end

  def call(%{request_path: "/webhook/linear"} = conn, _opts) do
    {:ok, payload, conn} = read_body(conn)

    with [signature_in_header] <- get_req_header(conn, "linear-signature"),
         {:ok, event} <- Jason.decode(payload),
         {:ok, integration} <- Integrations.get_by(provider: :linear),
         {:ok, %{"webhook_secret" => secret}} <- Jason.decode(integration.access_token),
         true <- verify_signature(payload, secret, signature_in_header) || {:error, :invalid_signature} do
      :ok = Devhub.Integrations.Linear.Webhook.handle(integration, event)
      conn |> send_resp(200, "OK") |> halt()
    else
      {:error, :integration_not_found} -> conn |> send_resp(200, "OK") |> halt()
      _error -> conn |> send_resp(403, "Forbidden") |> halt()
    end
  end

  def call(conn, _opts), do: conn

  defp verify_signature(payload, secret, signature_in_header) do
    :hmac
    |> :crypto.mac(:sha256, secret, payload)
    |> Base.encode16(case: :lower)
    |> Plug.Crypto.secure_compare(signature_in_header)
  end
end
