defmodule Devhub.Integrations.AI.Actions.RecommendQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations
  alias Devhub.Integrations.AI.Anthropic
  alias Devhub.Integrations.AI.Google
  alias Devhub.Integrations.AI.Schemas.Conversation
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.Adapter
  alias Devhub.Users.Schemas.OrganizationUser

  @callback recommend_query(OrganizationUser.t(), String.t(), Conversation.t()) ::
              {:ok, String.t()} | {:error, String.t()}
  def recommend_query(organization_user, database_id, conversation) do
    {:ok, database} =
      QueryDesk.get_database(id: database_id, organization_id: organization_user.organization_id)

    schema = Adapter.get_schema(database, organization_user.user_id)
    {:ok, integration} = Integrations.get_by(organization_id: organization_user.organization_id, provider: :ai)

    messages = Enum.reverse(conversation.messages)

    result =
      if is_nil(integration.access_token) do
        {:error, :not_configured}
      else
        case integration.settings["general_model"] do
          "claude" <> _rest ->
            Anthropic.recommend_query(integration, database.adapter, schema, messages)

          "gemini" <> _rest ->
            Google.recommend_query(integration, database.adapter, schema, messages)
        end
      end

    maybe_strip_sql_block(result)
  end

  defp maybe_strip_sql_block({:ok, query}) do
    query =
      query
      |> String.trim()
      |> String.replace_leading("```sql", "")
      |> String.replace_trailing("```", "")
      |> String.trim()

    {:ok, query}
  end

  defp maybe_strip_sql_block(result), do: result
end
