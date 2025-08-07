defmodule Devhub.Integrations.GitHub.AppToken do
  @moduledoc false
  use Joken.Config

  @impl true
  def token_config do
    [default_exp: 60, skip: [:aud, :iat, :nbf, :jti]]
    |> default_claims()
    |> add_claim("iat", fn -> DateTime.to_unix(DateTime.utc_now()) end)
  end
end
