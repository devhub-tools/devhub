defmodule Devhub.Licensing.Client do
  @moduledoc false

  use Tesla

  alias Devhub.Users.Schemas.Organization

  require Logger

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.BaseUrl, Application.fetch_env!(:devhub, :licensing_base_url)

  @spec register_installation(Organization.t(), binary()) :: {:ok, String.t()}
  def register_installation(organization, public_key) do
    {:ok, %{body: %{"installation_id" => installation_id}}} =
      post("/installations", %{
        organization_id: organization.id,
        app_url: DevhubWeb.Endpoint.url(),
        public_key: Base.encode64(public_key),
        installed_version: System.get_env("APP_VERSION", "empty")
      })

    {:ok, installation_id}
  end

  @spec update_installation(Organization.t()) :: Tesla.Env.result()
  def update_installation(organization) do
    timestamp = DateTime.to_unix(DateTime.utc_now())
    app_url = DevhubWeb.Endpoint.url()
    installed_version = System.get_env("APP_VERSION", "empty")

    signature =
      :public_key.sign(
        to_string(timestamp) <> organization.installation_id <> app_url <> installed_version,
        nil,
        {:ed_pri, :ed25519, nil, organization.private_key},
        []
      )

    patch("/installations/#{organization.installation_id}", %{
      signature: Base.encode64(signature),
      timestamp: timestamp,
      app_url: app_url,
      installed_version: installed_version,
      organization_name: organization.name
    })
  end

  @spec verify_user(String.t(), Organization.t()) :: {:ok, map()} | {:error, :invalid_token}
  def verify_user(token, organization) do
    signature =
      :public_key.sign(token <> organization.installation_id, nil, {:ed_pri, :ed25519, nil, organization.private_key}, [])

    "/installations/verify-user"
    |> post(%{
      token: token,
      installation_id: organization.installation_id,
      signature: Base.encode64(signature)
    })
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      _error ->
        {:error, :invalid_token}
    end
  end
end
