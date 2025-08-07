defmodule DevhubWeb.Proxy.Postgres.Handshake do
  @moduledoc false

  alias DevhubWeb.Proxy.Postgres.ClientState

  def handshake(%ClientState{conn: conn} = state) do
    # send S to let client know ssl is supported and then start handshake
    :ok = :gen_tcp.send(conn, <<?S>>)

    {:ok, conn} =
      :ssl.handshake(conn,
        certs_keys: [
          %{
            certfile: Application.fetch_env!(:devhub, :proxy_tls_cert_file),
            keyfile: Application.fetch_env!(:devhub, :proxy_tls_key_file)
          }
        ]
      )

    Map.put(state, :conn, conn)
  end
end
