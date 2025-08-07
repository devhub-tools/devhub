defmodule Devhub.Integrations.GitHub.Actions.ImportUsersTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Repo
  alias Tesla.Adapter.Finch

  test "import_users/1" do
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    organization = insert(:organization)
    integration = insert(:integration, organization: organization, settings: %{"login" => "devhub-tools"})
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
                              body: body,
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
      assert %{
               "query" => "query ListUsers" <> _query,
               "variables" => %{
                 "login" => "devhub-tools",
                 "cursor" => nil
               }
             } = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "organization" => %{
              "membersWithRole" => %{
                "nodes" => [
                  %{"login" => "michaelst"},
                  %{"login" => "gaiabeatrice"},
                  %{"login" => "devtayls"},
                  %{"login" => "amalmborg97"},
                  %{"login" => "Bristclair13"}
                ],
                "pageInfo" => %{
                  "endCursor" => "Y3Vyc29yOnYyOpHOCLKmMA==",
                  "hasNextPage" => false
                }
              }
            }
          }
        }
      )
    end)

    assert :ok = GitHub.import_users(integration)

    assert [
             %{username: "Bristclair13"},
             %{username: "amalmborg97"},
             %{username: "devtayls"},
             %{username: "gaiabeatrice"},
             %{username: "michaelst"}
           ] = GitHub.User |> Repo.all() |> Enum.sort_by(& &1.username)
  end

  test "loops until has next page is false" do
    app_token = Ecto.UUID.generate()
    installation_token = Ecto.UUID.generate()
    organization = insert(:organization)
    integration = insert(:integration, organization: organization, settings: %{"login" => "devhub-tools"})

    expect(GitHub, :get_app_token, 2, fn _integration ->
      {:ok, app_token}
    end)

    Finch
    |> expect(:call, fn %Tesla.Env{method: :post, url: url}, _opts ->
      assert url == "https://api.github.com/app/installations/#{integration.external_id}/access_tokens"

      TeslaHelper.response(body: %{"token" => installation_token})
    end)
    |> expect(:call, fn %Tesla.Env{method: :post, url: "https://api.github.com/graphql", body: body}, _opts ->
      assert %{
               "query" => "query ListUsers" <> _query,
               "variables" => %{
                 "login" => "devhub-tools",
                 "cursor" => nil
               }
             } = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "organization" => %{
              "membersWithRole" => %{
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
               "query" => "query ListUsers" <> _query,
               "variables" => %{
                 "login" => "devhub-tools",
                 "cursor" => "test-cursor"
               }
             } = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "organization" => %{
              "membersWithRole" => %{
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

    assert :ok = GitHub.import_users(integration)
  end
end
