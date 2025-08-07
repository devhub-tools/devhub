defmodule Devhub.Integrations.GitHub.Client do
  @moduledoc false

  use Tesla
  use Nebulex.Caching

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.Schemas.Integration

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.BaseUrl, "https://api.github.com"

  plug Tesla.Middleware.Headers, [
    {"accept", "application/vnd.github.v3+json"},
    {"x-github-api-version", "2022-11-28"},
    {"user-agent", "Devhub"}
  ]

  plug Tesla.Middleware.JSON

  def convert_code(code) do
    post("/app-manifests/#{code}/conversions", %{})
  end

  @spec get_installation(String.t(), String.t()) :: Tesla.Env.result()
  def get_installation(organization_id, installation_id) do
    with {:ok, token} <- GitHub.get_app_token(organization_id) do
      get("app/installations/#{installation_id}",
        headers: [{"authorization", "Bearer #{token}"}]
      )
    end
  end

  @spec get_token(Integration.t()) :: String.t()
  def get_token(%Integration{external_id: installation_id} = integration) do
    {:ok, token} = GitHub.get_app_token(integration.organization_id)

    {:ok, %{body: %{"token" => token}}} =
      post("app/installations/#{installation_id}/access_tokens", %{}, headers: [{"authorization", "Bearer #{token}"}])

    token
  end

  @spec graphql(Integration.t(), String.t(), map()) :: Tesla.Env.result()
  def graphql(integration, query, variables \\ %{}) do
    token = get_token(integration)

    post("graphql", %{query: query, variables: variables}, headers: [{"authorization", "Bearer #{token}"}])
  end

  @decorate cacheable(
              cache: Devhub.Coverbot.Cache,
              key: "compare:#{repo}:#{base}:#{head}",
              opts: [ttl: to_timeout(minute: 1)]
            )
  def compare(integration, repo, base, head) do
    token = get_token(integration)

    get("repos/#{repo}/compare/#{base}...#{head}",
      headers: [{"authorization", "Bearer #{token}"}]
    )
  end

  def pull_request_files(integration, repository, number) do
    token = get_token(integration)

    get("repos/#{repository.owner}/#{repository.name}/pulls/#{number}/files?per_page=100",
      headers: [{"authorization", "Bearer #{token}"}]
    )
  end

  @spec commit(Integration.t(), Repository.t(), String.t()) :: Tesla.Env.result()
  def commit(integration, repository, sha) do
    token = get_token(integration)

    get("repos/#{repository.owner}/#{repository.name}/commits/#{sha}",
      headers: [{"authorization", "Bearer #{token}"}]
    )
  end

  def create_check(integration, repository, params) do
    token = get_token(integration)

    post("repos/#{repository.owner}/#{repository.name}/check-runs", params,
      headers: [{"authorization", "Bearer #{token}"}]
    )
  end
end
