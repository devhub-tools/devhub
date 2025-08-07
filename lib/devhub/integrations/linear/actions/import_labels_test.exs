defmodule Devhub.Integrations.Linear.Actions.ImportLabelsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.Linear
  alias Devhub.Integrations.Linear.Label

  test "import_labels/2" do
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
      assert %{"query" => "query ImportLabels" <> _rest, "variables" => %{"cursor" => nil}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "issueLabels" => %{
              "nodes" => [
                %{
                  "color" => "#eb5757",
                  "id" => "f9b19e69-3bc5-4047-8a51-90d58a14f8a2",
                  "name" => "Bug",
                  "isGroup" => false
                },
                %{
                  # should add # in front of color through changeset
                  "color" => "a2eeef",
                  "id" => "481a2ad7-4464-45e0-9659-059ffc3aafc6",
                  "name" => "Enhancements",
                  "isGroup" => false
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
      assert %{"query" => "query ImportLabels" <> _rest, "variables" => %{"cursor" => "test-cursor"}} =
               Jason.decode!(body)

      TeslaHelper.response(
        body: %{
          "data" => %{
            "issueLabels" => %{
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

    assert :ok == Linear.import_labels(integration)

    assert [
             %Label{
               name: "Bug",
               type: :feature,
               color: "#eb5757",
               external_id: "f9b19e69-3bc5-4047-8a51-90d58a14f8a2"
             },
             %Label{
               name: "Enhancements",
               type: :feature,
               color: "#a2eeef",
               external_id: "481a2ad7-4464-45e0-9659-059ffc3aafc6"
             }
           ] = Linear.list_labels(integration.organization_id)
  end
end
