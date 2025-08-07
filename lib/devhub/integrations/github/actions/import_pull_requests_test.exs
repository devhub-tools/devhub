defmodule Devhub.Integrations.GitHub.Actions.ImportPullRequestsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Integrations.GitHub.PullRequestReview
  alias Devhub.Repo
  alias Tesla.Adapter.Finch

  test "import_pull_request/3" do
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    review_external_id = Ecto.UUID.generate()
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
              "pullRequests" => %{
                "nodes" => [
                  %{
                    "number" => 3,
                    "title" => "DevOps testing",
                    "state" => "merged",
                    "changedFiles" => 2,
                    "deletions" => 1,
                    "additions" => 1,
                    "createdAt" => "2024-01-01 00:00:00",
                    "mergedAt" => "2024-01-01 00:00:00",
                    "isDraft" => false,
                    "totalCommentsCount" => 3,
                    "author" => %{
                      "login" => "michaelst"
                    },
                    "commits" => %{
                      "nodes" => [
                        %{
                          "commit" => %{
                            "oid" => "1234",
                            "message" => "fixed test",
                            "authoredDate" => "2024-01-01 00:00:00",
                            "additions" => 1,
                            "deletions" => 1,
                            "author" => %{
                              "user" => %{
                                "login" => "michaelst"
                              }
                            }
                          }
                        }
                      ]
                    },
                    "reviews" => %{
                      "nodes" => [
                        %{
                          "id" => review_external_id,
                          "createdAt" => "2024-01-01 00:00:00",
                          "author" => %{
                            "login" => "michaelst"
                          }
                        }
                      ]
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
      )
    end)

    assert :ok = GitHub.import_pull_requests(integration, repository, [])

    assert [
             %{
               id: pull_request_id,
               organization_id: ^organization_id,
               number: 3,
               title: "DevOps testing",
               repository_id: ^repo_id,
               state: "merged",
               additions: 1,
               deletions: 1,
               changed_files: 2,
               comments_count: 3,
               author: "michaelst",
               first_commit_authored_at: ~U[2024-01-01 00:00:00Z],
               opened_at: ~U[2024-01-01 00:00:00Z],
               merged_at: ~U[2024-01-01 00:00:00Z]
             }
           ] = Repo.all(PullRequest)

    assert [
             %{
               organization_id: ^organization_id,
               github_id: ^review_external_id,
               author: "michaelst",
               pull_request_id: ^pull_request_id
             }
           ] = Repo.all(PullRequestReview)

    assert [
             %{
               message: "fixed test",
               authors: [
                 %{
                   github_user: %{
                     username: "michaelst"
                   }
                 }
               ]
             }
           ] = Commit |> Repo.all() |> Repo.preload(authors: :github_user)
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
    |> expect(:call, fn %Tesla.Env{method: :post, url: "https://api.github.com/graphql"}, _opts ->
      TeslaHelper.response(
        body: %{
          "data" => %{
            "repository" => %{
              "pullRequests" => %{
                "nodes" => [],
                "pageInfo" => %{
                  "hasNextPage" => true,
                  "endCursor" => "test-cursor"
                }
              }
            }
          }
        }
      )
    end)
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://api.github.com/app/installations/#{integration.external_id}/access_tokens"

      TeslaHelper.response(body: %{"token" => installation_token})
    end)
    |> expect(:call, fn %Tesla.Env{method: :post, url: "https://api.github.com/graphql", body: body}, _opts ->
      assert %{
               "query" => "query PullRequests" <> _query,
               "variables" => %{
                 "owner" => "devhub-tools",
                 "name" => "devhub",
                 "branch" => "main",
                 "cursor" => "test-cursor"
               }
             } = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "repository" => %{
              "pullRequests" => %{
                "nodes" => [],
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

    assert :ok = GitHub.import_pull_requests(integration, repository, [])
  end
end
