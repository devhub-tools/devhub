defmodule Devhub.Integrations.AI.Anthropic do
  @moduledoc false

  alias Devhub.Integrations.AI.Anthropic.Client

  def complete_query(integration, schema, prefix, suffix) do
    case Client.complete_query(integration, schema, prefix, suffix) do
      {:ok, %{body: %{"content" => [%{"text" => prediction}]}}} ->
        {:ok, prediction}

      _error ->
        {:error, "Failed to complete query"}
    end
  end

  def recommend_query(integration, database_type, schema, messages) do
    case Client.recommend_query(integration, database_type, schema, messages) do
      {:ok, %{body: %{"content" => [%{"text" => prediction}]}}} ->
        {:ok, prediction}

      _error ->
        {:error, "Failed to complete query"}
    end
  end

  def conversation_title(integration, question) do
    case Client.conversation_title(integration, question) do
      {:ok, %{body: %{"content" => [%{"text" => title}]}}} ->
        {:ok, String.trim(title)}

      _error ->
        {:ok, "No title"}
    end
  end
end
