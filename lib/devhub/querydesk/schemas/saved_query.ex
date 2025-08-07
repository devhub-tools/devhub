defmodule Devhub.QueryDesk.Schemas.SavedQuery do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Shared.Schemas.LabeledObject
  alias Devhub.Users.Organization
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  @type t :: %__MODULE__{
          title: String.t(),
          query: String.t(),
          private: boolean(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "sq"}
  schema "querydesk_saved_queries" do
    field :title, :string
    field :query, :string
    field :private, :boolean, default: false

    belongs_to :organization, Organization
    belongs_to :created_by_user, User

    has_many :labeled_objects, LabeledObject, foreign_key: :saved_query_id
    has_many :labels, through: [:labeled_objects, :label]

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:query, :title, :organization_id, :created_by_user_id, :private])
    |> validate_required([:query, :title, :organization_id, :private])
  end
end
