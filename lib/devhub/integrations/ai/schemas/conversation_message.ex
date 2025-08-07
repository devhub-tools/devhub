defmodule Devhub.Integrations.AI.Schemas.ConversationMessage do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Integrations.AI.Schemas.Conversation

  @type t :: %__MODULE__{
          sender: String.t(),
          message: String.t(),
          conversation: %Conversation{},
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "aim"}
  schema "ai_conversation_messages" do
    field :sender, Ecto.Enum, values: [:ai, :user]
    field :message, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :conversation, Conversation

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:sender, :message, :organization_id, :conversation_id])
    |> validate_required([:sender, :message, :organization_id, :conversation_id])
  end
end
