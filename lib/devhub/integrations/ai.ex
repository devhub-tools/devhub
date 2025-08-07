defmodule Devhub.Integrations.AI do
  @moduledoc false

  @behaviour Devhub.Integrations.AI.Actions.AddMessageToConversation
  @behaviour Devhub.Integrations.AI.Actions.CompleteQuery
  @behaviour Devhub.Integrations.AI.Actions.ConversationTitle
  @behaviour Devhub.Integrations.AI.Actions.GetConversations
  @behaviour Devhub.Integrations.AI.Actions.RecommendQuery
  @behaviour Devhub.Integrations.AI.Actions.StartConversation

  alias Devhub.Integrations.AI.Actions

  @impl Actions.CompleteQuery
  defdelegate complete_query(organization_user, database_id, prefix, suffix), to: Actions.CompleteQuery

  @impl Actions.RecommendQuery
  defdelegate recommend_query(organization_user, database_id, conversation), to: Actions.RecommendQuery

  @impl Actions.ConversationTitle
  defdelegate conversation_title(organization, question), to: Actions.ConversationTitle

  @impl Actions.GetConversations
  defdelegate get_conversations(organization_user, filters \\ []), to: Actions.GetConversations

  @impl Actions.StartConversation
  defdelegate start_conversation(params), to: Actions.StartConversation

  @impl Actions.AddMessageToConversation
  defdelegate add_message_to_conversation(conversation, sender, message), to: Actions.AddMessageToConversation
end
