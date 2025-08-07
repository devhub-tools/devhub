defmodule Devhub.Integrations.AI.Actions.CompleteQueryTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.AI
  alias Devhub.QueryDesk.Databases.Adapter
  alias Tesla.Adapter.Finch

  test "google" do
    organization = insert(:organization)

    organization_user = insert(:organization_user, organization: organization, permissions: %{super_admin: true})

    database = insert(:database, organization: organization)

    insert(:integration,
      organization: organization,
      access_token: "api-key",
      provider: :ai,
      settings: %{"query_model" => "gemini-1.5-flash"}
    )

    expect(Adapter, :get_schema, fn _database, _user_id ->
      []
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url:
                                "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=api-key"
                            },
                            _opts ->
      TeslaHelper.response(
        body: %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" =>
                      "from pull_request_reviews\njoin pull_requests on pull_request_reviews.pull_request_id = pull_requests.id\nwhere pull_requests.state = 'open'\nand pull_request_reviews.reviewed_at is null\norder by pull_requests.opened_at desc"
                  }
                ],
                "role" => "model"
              },
              "finishReason" => "MAX_TOKENS",
              "index" => 0,
              "safetyRatings" => [
                %{
                  "category" => "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                  "probability" => "NEGLIGIBLE"
                },
                %{
                  "category" => "HARM_CATEGORY_HATE_SPEECH",
                  "probability" => "NEGLIGIBLE"
                },
                %{
                  "category" => "HARM_CATEGORY_HARASSMENT",
                  "probability" => "NEGLIGIBLE"
                },
                %{
                  "category" => "HARM_CATEGORY_DANGEROUS_CONTENT",
                  "probability" => "NEGLIGIBLE"
                }
              ]
            }
          ],
          "modelVersion" => "gemini-1.5-flash-001",
          "usageMetadata" => %{
            "candidatesTokenCount" => 64,
            "promptTokenCount" => 2928,
            "totalTokenCount" => 2992
          }
        }
      )
    end)

    assert {:ok,
            "from pull_request_reviews\njoin pull_requests on pull_request_reviews.pull_request_id = pull_requests.id\nwhere pull_requests.state = 'open'\nand pull_request_reviews.reviewed_at is null\norder by pull_requests.opened_at desc"} =
             AI.complete_query(organization_user, database.id, "prefix", "suffix")
  end

  test "claude" do
    organization = insert(:organization)

    organization_user = insert(:organization_user, organization: organization, permissions: %{super_admin: true})

    database = insert(:database, organization: organization)

    insert(:integration,
      organization: organization,
      access_token: "api-key",
      provider: :ai,
      settings: %{"query_model" => "claude-3-5-haiku-20241022"}
    )

    expect(Adapter, :get_schema, fn _database, _user_id ->
      []
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :post,
                              url: "https://api.anthropic.com/v1/messages",
                              headers: [
                                {"x-api-key", "api-key"},
                                {"anthropic-version", "2023-06-01"},
                                {"anthropic-beta", "prompt-caching-2024-07-31"},
                                {"traceparent", _traceparent},
                                {"content-type", "application/json"}
                              ]
                            },
                            _opts ->
      TeslaHelper.response(
        body: %{
          "content" => [
            %{
              "text" => "FROM pull_request_reviews\nWHERE organization_id = 'your_organization_id'\nLIMIT 10",
              "type" => "text"
            }
          ],
          "id" => "msg_01RTho6wmqYy9eZaWWruNVSr",
          "model" => "claude-3-5-haiku-20241022",
          "role" => "assistant",
          "stop_reason" => "end_turn",
          "stop_sequence" => nil,
          "type" => "message",
          "usage" => %{
            "cache_creation_input_tokens" => 3166,
            "cache_read_input_tokens" => 0,
            "input_tokens" => 15,
            "output_tokens" => 28
          }
        }
      )
    end)

    assert {:ok, "FROM pull_request_reviews\nWHERE organization_id = 'your_organization_id'\nLIMIT 10"} =
             AI.complete_query(organization_user, database.id, "prefix", "suffix")
  end
end
