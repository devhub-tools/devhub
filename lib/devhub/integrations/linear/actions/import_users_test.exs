defmodule Devhub.Integrations.Linear.Actions.ImportUsersTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear

  test "import_users/2" do
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
      assert %{"query" => "query ImportUsers" <> _rest, "variables" => %{"cursor" => nil}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "users" => %{
              "nodes" => [
                %{
                  "id" => "7d5237a4-3e75-4cf5-b7e4-43535a186e17",
                  "name" => "Michael St Clair"
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
      assert %{"query" => "query ImportUsers" <> _rest, "variables" => %{"cursor" => "test-cursor"}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "users" => %{
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

    assert :ok == Linear.import_users(integration)
  end
end
