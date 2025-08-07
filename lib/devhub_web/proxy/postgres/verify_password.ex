defmodule DevhubWeb.Proxy.Postgres.VerifyPassword do
  @moduledoc false

  alias Devhub.Users
  alias DevhubWeb.Proxy.Postgres.ClientState

  def verify_password(sasl_data, %ClientState{conn: conn} = state) do
    c = if state.scram_state.channel_binding, do: "c=eSws", else: "c=biws"
    [^c, "r=" <> nonce, "p=" <> proof] = String.split(sasl_data, ",")

    stored_key = Base.decode64!(state.user.proxy_password.stored_key)
    server_key = Base.decode64!(state.user.proxy_password.server_key)

    client_first_message = "n=#{state.scram_state.username},r=#{state.scram_state.client_nonce}"

    server_first_message =
      "r=#{state.scram_state.client_nonce}#{state.scram_state.server_nonce},s=#{state.user.proxy_password.salt},i=32768"

    client_final_message_without_proof = "#{c},r=#{nonce}"

    auth_message =
      client_first_message <> "," <> server_first_message <> "," <> client_final_message_without_proof

    client_signature = :crypto.mac(:hmac, :sha256, stored_key, auth_message)

    client_key = :crypto.exor(client_signature, Base.decode64!(proof))
    compare_hash = :crypto.hash(:sha256, client_key)

    with true <- Plug.Crypto.secure_compare(stored_key, compare_hash),
         true <- DateTime.after?(state.user.proxy_password.expires_at, DateTime.utc_now()),
         {:ok, organization_user} <- Users.get_organization_user(user_id: state.user.id) do
      server_signature = :hmac |> :crypto.mac(:sha256, server_key, auth_message) |> Base.encode64()
      message = "v=#{server_signature}"
      length = byte_size(message) + 8

      :ok = :ssl.send(conn, <<?R, length::integer-size(32), 0, 0, 0, 12, message::binary>>)

      {:ok, %{state | organization_user: organization_user, scram_state: nil}}
    else
      _error ->
        error = <<?S, "FATAL", 0, ?V, "FATAL", 0, ?C, "28P01", 0, ?M, "invalid password", 0, ?R, "auth_failed", 0, 0>>

        length = byte_size(error) + 4
        msg = <<?E, length::integer-size(32), error::binary>>

        :ok = :ssl.send(conn, msg)

        {:error, :invalid_password}
    end
  end
end
