defmodule DevhubWeb.WellKnownControllerTest do
  use DevhubWeb.ConnCase, async: true

  @tag unauthenticated: true
  test "GET /.well-known/jwks.json", %{conn: conn} do
    private_key = JOSE.JWK.from_pem(Application.get_env(:devhub, :signing_key))
    kid = JOSE.JWK.thumbprint(private_key)

    assert %{
             "keys" => [
               %{
                 "alg" => "ES256",
                 "crv" => "P-256",
                 "kty" => "EC",
                 "kid" => ^kid,
                 "use" => "sig",
                 "x" => _x,
                 "y" => _y
               }
             ]
           } = conn |> get(~p"/.well-known/jwks.json") |> json_response(200)
  end
end
