defmodule Devhub.Integrations.GitHub.Actions.GetAppTokenTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub

  test "get_app_token/1" do
    organization = insert(:organization)
    assert {:error, :failed_to_build_token} = GitHub.get_app_token(organization.id)

    %{client_id: client_id} = insert(:github_app, organization: organization)

    assert {:ok, token} = GitHub.get_app_token(organization.id)

    assert %JOSE.JWT{
             fields: %{
               "exp" => exp,
               "iat" => iat,
               "iss" => ^client_id
             }
           } = JOSE.JWT.peek(token)

    timestamp = DateTime.to_unix(DateTime.utc_now())
    assert (exp - timestamp) in [59, 60]
    assert (timestamp - iat) in [0, 1]
  end
end
