defmodule Devhub.Integrations.AI.Google do
  @moduledoc false

  alias Devhub.Integrations.AI.Google.Client

  def complete_query(integration, schema, prefix, suffix) do
    case Client.complete_query(integration, schema, prefix, suffix) do
      {:ok, %{body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => prediction}]}}]}}} ->
        {:ok, prediction}

      _error ->
        {:error, "Failed to complete query"}
    end
  end

  def recommend_query(integration, database_type, schema, messages) do
    case Client.recommend_query(integration, database_type, schema, messages) do
      {:ok, %{body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => prediction}]}}]}}} ->
        prediction =
          prediction
          |> String.replace("```sql", "")
          |> String.replace("```", "")
          |> String.trim()

        {:ok, prediction}

      _error ->
        {:error, "Failed to complete query"}
    end
  end

  def conversation_title(integration, question) do
    case Client.conversation_title(integration, question) do
      {:ok, %{body: %{"candidates" => [%{"content" => %{"parts" => [%{"text" => title}]}}]}}} ->
        {:ok, String.trim(title)}

      _error ->
        {:ok, "No title"}
    end
  end
end
