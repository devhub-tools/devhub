defmodule Devhub.Integrations.Google do
  @moduledoc false
  alias Devhub.Integrations.Google.Client
  alias Devhub.Jwt

  @callback access_token(WorkloadIdentity.t()) :: {:ok, String.t()} | {:error, :failed_to_get_google_token}
  def access_token(workload_identity) do
    Client.get_token(workload_identity)
  end

  def workload_identity_claims(workspace_id) do
    private_key = Application.get_env(:devhub, :signing_key)
    signer = Joken.Signer.create("ES256", %{"pem" => private_key})

    {:ok, _jwt, claims} =
      Jwt.generate_and_sign(
        %{
          "aud" =>
            "https://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/providers/${PROVIDER}",
          "sub" => "workspace:#{workspace_id}",
          "terradesk_workspace_id" => workspace_id
        },
        signer
      )

    claims |> Jason.encode!() |> Jason.Formatter.pretty_print()
  end
end
