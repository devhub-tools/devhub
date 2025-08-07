defmodule Devhub.QueryDesk.Schemas.QueryComment do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  @type t :: %__MODULE__{
          comment: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "qc"}
  schema "querydesk_query_comments" do
    field :comment, :string

    belongs_to :organization, Organization
    belongs_to :query, Query
    belongs_to :created_by_user, User

    timestamps()
  end

  def create_changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:query_id, :created_by_user_id, :organization_id, :comment])
    |> validate_required([:query_id, :created_by_user_id, :organization_id, :comment])
  end

  def update_changeset(comment \\ %__MODULE__{}, params) do
    comment
    |> cast(params, [:comment])
    |> validate_required([:comment])
  end
end
