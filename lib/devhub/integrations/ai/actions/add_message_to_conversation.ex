defmodule Devhub.Integrations.AI.Actions.AddMessageToConversation do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.AI.Schemas.Conversation
  alias Devhub.Integrations.AI.Schemas.ConversationMessage
  alias Devhub.Repo

  @callback add_message_to_conversation(
              conversation :: Conversation.t(),
              sender :: :user | :ai,
              message :: String.t()
            ) :: {:ok, ConversationMessage.t()} | {:error, Ecto.Changeset.t()}
  def add_message_to_conversation(conversation, sender, message) do
    %{
      sender: sender,
      message: message,
      conversation_id: conversation.id,
      organization_id: conversation.organization_id
    }
    |> ConversationMessage.changeset()
    |> Repo.insert()
  end
end
