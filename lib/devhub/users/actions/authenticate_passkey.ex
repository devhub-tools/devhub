defmodule Devhub.Users.Actions.AuthenticatePasskey do
  @moduledoc false
  @behaviour __MODULE__

  @callback authenticate_passkey(map(), Wax.Challenge.t(), list()) :: :ok | :error
  def authenticate_passkey(params, challenge, allow_credentials) do
    with {:ok, authenticator_data} <- Base.decode64(params["authenticatorData"]),
         {:ok, signature} <- Base.decode64(params["sig"]),
         {:ok, _authenticator_data} <-
           Wax.authenticate(
             params["rawId"],
             authenticator_data,
             signature,
             params["clientDataJSON"],
             challenge,
             allow_credentials
           ) do
      :ok
    else
      _error -> :error
    end
  end
end
