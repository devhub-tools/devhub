defmodule Devhub.Integrations.GitHub.Actions.ImportDefaultBranchTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Repo
  alias Tesla.Adapter.Finch

  test "import_default_branch/3" do
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    %{id: organization_id} = organization = insert(:organization)
    integration = insert(:integration, organization: organization)
    %{id: repo_id} = repository = insert(:repository, organization: organization)
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
              "defaultBranchRef" => %{
                "target" => %{
                  "history" => %{
                    "nodes" => [
                      %{
                        "oid" => "123456",
                        "message" => "fixed test",
                        "authoredDate" => "2024-01-01 00:00:00",
                        "additions" => 1,
                        "deletions" => 1,
                        "author" => %{
                          "user" => %{
                            "login" => "Michaelst57"
                          }
                        }
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
          }
        }
      )
    end)

    assert :ok == GitHub.import_default_branch(integration, repository, [])

    assert [
             %Commit{
               organization_id: ^organization_id,
               message: "fixed test",
               sha: "123456"
             }
           ] = Repo.all(from(Commit, where: [repository_id: ^repo_id]))
  end

  test "loops until has next page is false" do
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    organization = insert(:organization)
    integration = insert(:integration, organization: organization)
    repository = insert(:repository, organization: organization)

    expect(GitHub, :get_app_token, 2, fn _integration ->
      {:ok, app_token}
    end)

    Finch
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://api.github.com/app/installations/#{integration.external_id}/access_tokens"
      TeslaHelper.response(body: %{"token" => installation_token})
    end)
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://api.github.com/graphql"

      TeslaHelper.response(
        body: %{
          "data" => %{
            "repository" => %{
              "defaultBranchRef" => %{
                "target" => %{
                  "history" => %{
                    "nodes" => [],
                    "pageInfo" => %{
                      "hasNextPage" => true,
                      "endCursor" => "test-cursor"
                    }
                  }
                }
              }
            }
          }
        }
      )
    end)
    # should make second http call
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://api.github.com/app/installations/#{integration.external_id}/access_tokens"
      TeslaHelper.response(body: %{"token" => installation_token})
    end)
    |> expect(:call, fn %Tesla.Env{method: :post, url: url, body: body}, _opts ->
      assert url == "https://api.github.com/graphql"

      assert %{
               "query" => "query GetDefaultBranchCommits" <> _query,
               "variables" => %{"cursor" => "test-cursor", "name" => "devhub", "owner" => "devhub-tools", "since" => nil}
             } = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "repository" => %{
              "defaultBranchRef" => %{
                "target" => %{
                  "history" => %{
                    "nodes" => [],
                    "pageInfo" => %{
                      "hasNextPage" => false,
                      "endCursor" => nil
                    }
                  }
                }
              }
            }
          }
        }
      )
    end)

    assert :ok == GitHub.import_default_branch(integration, repository, [])
  end
end
