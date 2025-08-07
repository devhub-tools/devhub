defmodule Devhub.Integrations.GitHub.Actions.ImportRepositoriesTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Tesla.Adapter.Finch

  test "import_repositories/2" do
    organization = insert(:organization)
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    integration = insert(:integration, organization: organization, provider: :github)
    url = "https://api.github.com/app/installations/#{integration.external_id}/access_tokens"

    expect(GitHub, :get_app_token, fn _integration ->
      {:ok, app_token}
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: ^url,
                              headers: [
                                {"authorization", "Bearer " <> ^app_token},
                                {"traceparent", _traceparent},
                                {"accept", "application/vnd.github.v3+json"},
                                {"x-github-api-version", "2022-11-28"},
                                {"user-agent", "Devhub"},
                                {"content-type", "application/json"}
                              ]
                            },
                            _opts ->
      TeslaHelper.response(body: %{"token" => installation_token})
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: "https://api.github.com/graphql",
                              headers: [
                                {"authorization", "Bearer " <> ^installation_token},
                                {"traceparent", _traceparent},
                                {"accept", "application/vnd.github.v3+json"},
                                {"x-github-api-version", "2022-11-28"},
                                {"user-agent", "Devhub"},
                                {"content-type", "application/json"}
                              ]
                            },
                            _opts ->
      TeslaHelper.response(
        body: %{
          "data" => %{
            "organization" => %{
              "repositories" => %{
                "nodes" => [
                  %{
                    "owner" => %{
                      "login" => "michaelst"
                    },
                    "name" => "Devhub",
                    "pushedAt" => "2024-01-01 00:00:00",
                    "isArchived" => false
                  }
                ],
                "pageInfo" => %{
                  "hasNextPage" => false,
                  "endCursor" => nil
                }
              }
            }
          }
        }
      )
    end)

    assert :ok == GitHub.import_repositories(integration)
  end
end
