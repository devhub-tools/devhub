defmodule Devhub.Users.Actions.GenerateProxyPassword do
  @moduledoc false

  alias Devhub.Users

  @callback generate_proxy_password(User.t(), integer()) :: {:ok, String.t()} | {:error, :failed_to_generate_password}
  def generate_proxy_password(user, duration) do
    password = Devhub.Utils.Base58.encode(:crypto.strong_rand_bytes(32))
    salt = :crypto.strong_rand_bytes(16)
    iterations = 32_768

    salted_password = :crypto.pbkdf2_hmac(:sha256, password, salt, iterations, 32)
    client_key = :crypto.mac(:hmac, :sha256, salted_password, "Client Key")
    stored_key = :crypto.hash(:sha256, client_key)
    server_key = :crypto.mac(:hmac, :sha256, salted_password, "Server Key")

    user
    |> Users.update_user(%{
      proxy_password: %{
        salt: Base.encode64(salt),
        stored_key: Base.encode64(stored_key),
        server_key: Base.encode64(server_key),
        expires_at: DateTime.add(DateTime.utc_now(), duration, :second)
      }
    })
    |> case do
      {:ok, _user} ->
        {:ok, password}

      _error ->
        {:error, :failed_to_generate_password}
    end
  end
end
