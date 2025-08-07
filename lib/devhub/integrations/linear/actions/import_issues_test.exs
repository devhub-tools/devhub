defmodule Devhub.Integrations.Linear.Actions.ImportIssuesTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "import_issues/4" do
    access_token = Ecto.UUID.generate()
    organization = insert(:organization)

    integration =
      insert(:integration,
        organization: organization,
        provider: :github,
        access_token: Jason.encode!(%{access_token: access_token})
      )

    label = insert(:linear_label, organization: organization)

    Tesla.Adapter.Finch
    |> expect(:call, fn %Tesla.Env{
                          method: :post,
                          url: "https://api.linear.app/graphql",
                          body: body,
                          headers: [
                            {"authorization", "Bearer " <> ^access_token},
                            {"traceparent", _traceparent},
                            {"user-agent", "Devhub Metrics"},
                            {"content-type", "application/json"}
                          ]
                        },
                        _opts ->
      assert %{"variables" => %{"cursor" => nil, "since" => "-P1D"}} = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "issues" => %{
              "nodes" => [
                %{
                  "archivedAt" => "2024-01-01 00:00:00",
                  "canceledAt" => "2024-01-01 00:00:00",
                  "completedAt" => "2024-01-01 00:00:00",
                  "createdAt" => "2024-01-01 00:00:00",
                  "estimate" => 4,
                  "id" => "12345",
                  "identifier" => "DVOPS-1380",
                  "startedAt" => "2024-01-01 00:00:00",
                  "title" => "OOO",
                  "url" => "https://api.linear.app/graphql",
                  "labels" => %{
                    "nodes" => [
                      %{
                        "id" => label.external_id
                      }
                    ]
                  },
                  "assignee" => %{
                    "id" => "1a2b",
                    "name" => "michaelst"
                  },
                  "team" => %{
                    "id" => "2468"
                  }
                }
              ],
              "pageInfo" => %{
                "hasNextPage" => true,
                "endCursor" => "test-cursor"
              }
            }
          }
        }
      )
    end)
    |> expect(:call, fn %Tesla.Env{
                          method: :post,
                          url: "https://api.linear.app/graphql",
                          body: body,
                          headers: [
                            {"authorization", "Bearer " <> ^access_token},
                            {"traceparent", _traceparent},
                            {"user-agent", "Devhub Metrics"},
                            {"content-type", "application/json"}
                          ]
                        },
                        _opts ->
      assert %{"variables" => %{"cursor" => "test-cursor", "since" => "-P1D"}} = Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "issues" => %{
              "nodes" => [],
              "pageInfo" => %{
                "hasNextPage" => false,
                "endCursor" => nil
              }
            }
          }
        }
      )
    end)

    assert :ok == Linear.import_issues(integration, "-P1D")
  end
end
