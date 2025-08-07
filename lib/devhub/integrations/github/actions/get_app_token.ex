defmodule Devhub.Integrations.GitHub.Actions.GetAppToken do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.AppToken

  require Logger

  @callback get_app_token(String.t()) :: {:ok, String.t()} | {:error, :failed_to_build_token}
  def get_app_token(organization_id) do
    with {:ok, app} <- GitHub.get_app(organization_id: organization_id),
         signer = Joken.Signer.create("RS256", %{"pem" => app.private_key}),
         {:ok, token, _claims} <- AppToken.generate_and_sign(%{"iss" => app.client_id}, signer) do
      {:ok, token}
    else
      error ->
        Logger.error("Failed to build token: #{inspect(error)}")
        {:error, :failed_to_build_token}
    end
  end
end
