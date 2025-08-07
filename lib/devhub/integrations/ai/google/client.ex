defmodule Devhub.Integrations.AI.Google.Client do
  @moduledoc false
  use Tesla

  import Devhub.Integrations.AI.Utils.FormatDatabaseSchema

  plug Tesla.Middleware.OpenTelemetry
  plug Tesla.Middleware.BaseUrl, "https://generativelanguage.googleapis.com/v1beta"
  plug Tesla.Middleware.JSON

  def complete_query(integration, schema, prefix, suffix) do
    post("/models/#{integration.settings["query_model"]}:generateContent?key=#{integration.access_token}", %{
      generationConfig: %{maxOutputTokens: 64, temperature: 0.0},
      contents: [
        %{
          parts: [
            %{
              text: """
              You are a "sql" programmer that replaces <FILL_ME> part with the right code. Only output the code that replaces <FILL_ME> part. Do not add any explanation or markdown.

              Assume a database with the following tables and columns exists:

              #{format_database_schema(schema)}
              """
            },
            %{text: "#{prefix}<FILL_ME>#{suffix}"}
          ]
        }
      ],
      safetySettings: [
        %{
          category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          threshold: "BLOCK_ONLY_HIGH"
        },
        %{
          category: "HARM_CATEGORY_HATE_SPEECH",
          threshold: "BLOCK_ONLY_HIGH"
        },
        %{
          category: "HARM_CATEGORY_HARASSMENT",
          threshold: "BLOCK_ONLY_HIGH"
        },
        %{
          category: "HARM_CATEGORY_DANGEROUS_CONTENT",
          threshold: "BLOCK_ONLY_HIGH"
        }
      ]
    })
  end

  def recommend_query(integration, database_type, schema, messages) do
    contents =
      Enum.map(messages, fn message ->
        %{
          role: (message.sender == :ai && "model") || "user",
          parts: [
            %{
              text: message.message
            }
          ]
        }
      end)

    post("/models/#{integration.settings["general_model"]}:generateContent?key=#{integration.access_token}", %{
      generationConfig: %{maxOutputTokens: 1024, temperature: 0.0},
      system_instruction: %{
        parts: [
          %{
            text:
              "I need help generating #{database_type} queries to retrieve data from my database. I need just the raw SQL with no descriptions or markdown so I can run the query directly. I have this database with the following tables and columns:"
          },
          %{text: format_database_schema(schema)}
        ]
      },
      contents: contents,
      safetySettings: [
        %{category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH"}
      ]
    })
  end

  def conversation_title(integration, question) do
    post("/models/#{integration.settings["general_model"]}:generateContent?key=#{integration.access_token}", %{
      generationConfig: %{maxOutputTokens: 50},
      contents: [
        %{
          role: "user",
          parts: [
            %{
              text:
                "Give me a single short title with no formatting for a conversation that starts with this request: #{question}"
            }
          ]
        }
      ],
      safetySettings: [
        %{category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH"},
        %{category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH"}
      ]
    })
  end
end
