defmodule Devhub.Users.Actions.GenerateProxyPasswordTest do
  use Devhub.DataCase, async: true

  test "generate_proxy_password/2" do
    user = insert(:user)
    {:ok, proxy_password} = Devhub.Users.generate_proxy_password(user, 3600)

    # ensure the saved values are correct for the returned password
    %{
      proxy_password: %{
        server_key: server_key,
        stored_key: stored_key,
        salt: salt
      }
    } = Devhub.Repo.get(Devhub.Users.User, user.id)

    server_nonce = 16 |> :crypto.strong_rand_bytes() |> Base.encode64()

    ["SCRAM-SHA-256", 0, <<0, 0, 0, 32>>, "n,,n=,r=", client_nonce] = Postgrex.SCRAM.client_first()

    {
      [["c=biws,r=", _nonce], ",p=", proof],
      %{auth_message: auth_message} = scram_state
    } = Postgrex.SCRAM.client_final("r=#{client_nonce}#{server_nonce},s=#{salt},i=32768", password: proxy_password)

    client_signature = :crypto.mac(:hmac, :sha256, Base.decode64!(stored_key), auth_message)

    client_key = :crypto.exor(client_signature, Base.decode64!(proof))
    compare_hash = :crypto.hash(:sha256, client_key)

    assert compare_hash == Base.decode64!(stored_key)

    server_signature = :hmac |> :crypto.mac(:sha256, Base.decode64!(server_key), auth_message) |> Base.encode64()
    assert :ok = Postgrex.SCRAM.verify_server("v=#{server_signature}", scram_state, password: proxy_password)
  end
end
