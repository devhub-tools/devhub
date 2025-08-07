defmodule Devhub.Integrations.GitHubTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.GitHub.Storage
  alias Tesla.Adapter.Finch

  test "get_user/1" do
    %{id: organization_id} = build(:organization)
    %{id: github_user_id} = github_user = build(:github_user, organization_id: organization_id)

    expect(Storage, :get_user, fn [id: ^github_user_id] -> {:ok, github_user} end)
    assert {:ok, github_user} == GitHub.get_user(id: github_user_id)
  end

  test "list_repositories/1" do
    %{id: organization_id} = build(:organization)
    repo = build(:repository, organization_id: organization_id)

    expect(Storage, :list_repositories, fn ^organization_id -> [repo] end)
    assert [repo] == GitHub.list_repositories(organization_id)
  end

  test "update_repository/2" do
    %{id: organization_id} = build(:organization)
    %{id: repo_id} = repo = build(:repository, organization_id: organization_id)
    attrs = %{name: "github_test"}

    expect(Storage, :update_repository, fn ^repo, ^attrs ->
      {:ok, %{repo | name: "github_test"}}
    end)

    assert {:ok,
            %Repository{
              id: ^repo_id,
              name: "github_test"
            }} = GitHub.update_repository(repo, attrs)
  end

  test "get_repository/1" do
    %{id: organization_id} = build(:organization)
    repo = build(:repository, organization_id: organization_id)
    name = repo.name

    expect(Storage, :get_repository, fn [name: ^name] -> {:ok, repo} end)
    assert {:ok, ^repo} = GitHub.get_repository(name: name)
  end

  test "pull_request_details/3" do
    %{id: organization_id} = build(:organization)
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    integration = build(:integration, organization_id: organization_id, provider: :github)
    %{id: repo_id} = repository = build(:repository, organization_id: organization_id)
    pull_request = build(:pull_request, organization_id: organization_id, repository_id: repo_id)
    number = pull_request.number
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
            "repository" => %{
              "pullRequest" => %{
                "reviews" => %{
                  "nodes" => [
                    %{
                      "createdAt" => "2024-01-01 00:00:00"
                    }
                  ]
                },
                "commits" => %{
                  "nodes" => [
                    %{
                      "commit" => %{
                        "authoredDate" => "2024-01-01 00:00:00"
                      }
                    }
                  ]
                }
              }
            }
          }
        }
      )
    end)

    assert %{
             "commits" => %{"nodes" => [%{"commit" => %{"authoredDate" => "2024-01-01 00:00:00"}}]},
             "reviews" => %{"nodes" => [%{"createdAt" => "2024-01-01 00:00:00"}]}
           } == GitHub.pull_request_details(integration, repository, number)
  end
end
