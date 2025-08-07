defmodule Devhub.Integrations.AI.Anthropic.Client do
  @moduledoc false
  use Tesla

  import Devhub.Integrations.AI.Utils.FormatDatabaseSchema

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.BaseUrl, "https://api.anthropic.com/v1"
  plug Tesla.Middleware.JSON

  def complete_query(integration, schema, prefix, suffix) do
    post(
      "/messages",
      %{
        model: integration.settings["query_model"],
        max_tokens: 64,
        temperature: 0.0,
        system: [
          %{
            type: "text",
            cache_control: %{type: "ephemeral"},
            text: """
            You are a "sql" programmer that replaces <FILL_ME> part with the right code. Only output the code that replaces <FILL_ME> part. Do not add any explanation or markdown.

            Assume a database with the following tables and columns exists:

            #{format_database_schema(schema)}
            """
          }
        ],
        messages: [%{role: "user", content: "#{prefix}<FILL_ME>#{suffix}"}]
      },
      headers: [
        {"x-api-key", integration.access_token},
        {"anthropic-version", "2023-06-01"},
        {"anthropic-beta", "prompt-caching-2024-07-31"}
      ]
    )
  end

  def recommend_query(integration, database_type, schema, messages) do
    messages =
      Enum.map(messages, fn message ->
        %{role: (message.sender == :ai && "assistant") || "user", content: message.message}
      end)

    post(
      "/messages",
      %{
        model: integration.settings["general_model"],
        max_tokens: 1024,
        system: [
          %{
            type: "text",
            text:
              "Transform the following natural language requests into valid SQL queries for #{database_type}. Assume a database with the following tables and columns exists:"
          },
          %{
            type: "text",
            cache_control: %{type: "ephemeral"},
            text: format_database_schema(schema)
          },
          %{
            type: "text",
            text:
              "Provide the SQL query that would retrieve the data based on the natural language request. Do not add any explanation or markdown."
          }
        ],
        messages: messages
      },
      headers: [
        {"x-api-key", integration.access_token},
        {"anthropic-version", "2023-06-01"},
        {"anthropic-beta", "prompt-caching-2024-07-31"}
      ]
    )
  end

  def conversation_title(integration, question) do
    post(
      "/messages",
      %{
        model: integration.settings["general_model"],
        max_tokens: 30,
        messages: [
          %{
            role: "user",
            content:
              "Give me a single short title with no formatting for a conversation that starts with this request: #{question}"
          }
        ]
      },
      headers: [
        {"x-api-key", integration.access_token},
        {"anthropic-version", "2023-06-01"}
      ]
    )
  end
end
