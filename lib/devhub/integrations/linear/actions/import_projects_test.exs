defmodule Devhub.Integrations.Linear.Actions.ImportProjectsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "import_projects/3" do
    access_token = Ecto.UUID.generate()

    integration =
      insert(:integration,
        provider: :linear,
        access_token: Jason.encode!(%{access_token: access_token})
      )

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
      assert %{"query" => "query ImportProjects" <> _rest, "variables" => %{"cursor" => nil, "since" => "-P1D"}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "projects" => %{
              "nodes" => [
                %{
                  "archivedAt" => "2024-01-01 00:00:00",
                  "canceledAt" => "2024-01-01 00:00:00",
                  "completedAt" => "2024-01-01 00:00:00",
                  "createdAt" => "2024-01-01 00:00:00",
                  "id" => "12345",
                  "name" => "DevOps testing",
                  "status" => %{
                    "name" => "merged"
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
    # should loop because previous response indicates there is a next page
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
      assert %{"query" => "query ImportProjects" <> _rest, "variables" => %{"cursor" => "test-cursor", "since" => "-P1D"}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "projects" => %{
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

    assert :ok == Linear.import_projects(integration, "-P1D")
  end
end
