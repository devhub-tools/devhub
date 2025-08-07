defmodule Devhub.Integrations.AI.Actions.StartConversation do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.AI.Schemas.Conversation

  @callback start_conversation(map()) :: {:ok, Conversation.t()} | {:error, Ecto.Changeset.t()}
  def start_conversation(params) do
    params
    |> Conversation.changeset()
    |> Devhub.Repo.insert()
  end
end
