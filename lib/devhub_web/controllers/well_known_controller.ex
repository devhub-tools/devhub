defmodule DevhubWeb.WellKnownController do
  use DevhubWeb, :controller

  def discovery(conn, _params) do
    json(conn, %{
      issuer: Application.get_env(:devhub, :issuer),
      jwks_uri: "#{DevhubWeb.Endpoint.url()}/.well-known/jwks.json"
    })
  end

  def jwks(conn, _params) do
    private_key = JOSE.JWK.from_pem(Application.get_env(:devhub, :signing_key))
    kid = JOSE.JWK.thumbprint(private_key)
    private_key = JOSE.JWK.merge(private_key, %{"use" => "sig", "alg" => "ES256", "kid" => kid})
    {_headers, public_key} = private_key |> JOSE.JWK.to_public() |> JOSE.JWK.to_map()

    json(conn, %{keys: [public_key]})
  end

  def microsoft_identity_association(conn, _params) do
    json(conn, %{
      associatedApplications: [
        %{
          applicationId: "31475c01-30c4-4519-9c32-11f91f38d789"
        }
      ]
    })
  end
end
