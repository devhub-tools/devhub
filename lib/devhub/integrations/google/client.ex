defmodule Devhub.Integrations.Google.Client do
  @moduledoc false
  use Tesla

  alias Devhub.Jwt
  alias Devhub.TerraDesk.Schemas.WorkloadIdentity

  require Logger

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.JSON

  @callback get_token(WorkloadIdentity.t()) :: {:ok, String.t()} | {:error, :failed_to_get_google_token}
  def get_token(workload_identity) do
    private_key = Application.get_env(:devhub, :signing_key)
    signer = Joken.Signer.create("ES256", %{"pem" => private_key})

    with {:ok, token, _claims} <-
           Jwt.generate_and_sign(
             %{
               "aud" => "https://iam.googleapis.com/#{workload_identity.provider}",
               "sub" => "workspace:#{workload_identity.workspace_id}",
               "terradesk_workspace_id" => workload_identity.workspace_id
             },
             signer
           ),
         {:ok, %{body: %{"access_token" => sts_token}}} <-
           post("https://sts.googleapis.com/v1/token", %{
             "audience" => "//iam.googleapis.com/#{workload_identity.provider}",
             "grantType" => "urn:ietf:params:oauth:grant-type:token-exchange",
             "requestedTokenType" => "urn:ietf:params:oauth:token-type:access_token",
             "scope" => "https://www.googleapis.com/auth/cloud-platform",
             "subjectTokenType" => "urn:ietf:params:oauth:token-type:jwt",
             "subjectToken" => token
           }),
         {:ok, %{body: %{"accessToken" => access_token}}} <-
           post(
             "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/#{workload_identity.service_account_email}:generateAccessToken",
             %{
               "scope" => "https://www.googleapis.com/auth/cloud-platform"
             },
             headers: [{"Authorization", "Bearer #{sts_token}"}]
           ) do
      {:ok, access_token}
    else
      error ->
        Logger.error("Failed to get access token: #{inspect(error)}")
        {:error, :failed_to_get_google_token}
    end
  end
end
