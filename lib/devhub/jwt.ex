defmodule Devhub.Jwt do
  @moduledoc false
  use Joken.Config

  @impl true
  def token_config do
    issuer = Application.get_env(:devhub, :issuer)

    default_claims(iss: issuer, default_exp: 60, skip: [:aud])
  end
end
