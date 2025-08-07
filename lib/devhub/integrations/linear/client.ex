defmodule Devhub.Integrations.Linear.Client do
  @moduledoc false
  use Tesla

  alias Devhub.Integrations.Schemas.Integration

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.BaseUrl, "https://api.linear.app"

  plug Tesla.Middleware.Headers, [
    {"user-agent", "Devhub Metrics"}
  ]

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Timeout, timeout: 60_000

  @spec graphql(Integration.t() | String.t(), String.t(), map()) :: Tesla.Env.result()
  def graphql(integration_or_token, query, variables \\ %{})

  def graphql(%Integration{access_token: access_token}, query, variables) do
    %{"access_token" => token} = Jason.decode!(access_token)
    graphql(token, query, variables)
  end

  def graphql(token, query, variables) do
    post("graphql", %{query: query, variables: variables}, headers: [{"authorization", "Bearer #{token}"}])
  end
end
