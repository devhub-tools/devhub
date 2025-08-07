defmodule Devhub.Integrations.AI.Schemas.Conversation do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Integrations.AI.Schemas.ConversationMessage

  @type t :: %__MODULE__{
          title: String.t(),
          messages: [%ConversationMessage{}],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "aic"}
  schema "ai_conversations" do
    field :title, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :user, Devhub.Users.User

    has_many :messages, ConversationMessage, preload_order: [desc: :inserted_at]

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:title, :organization_id, :user_id])
    |> put_assoc(:messages, attrs[:messages])
    |> validate_required([:title, :organization_id, :user_id])
  end
end
