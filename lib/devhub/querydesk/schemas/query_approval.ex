defmodule Devhub.QueryDesk.Schemas.QueryApproval do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Query
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  @type t :: %__MODULE__{
          query: String.t(),
          approved_at: DateTime.t()
        }

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "qry_apr"}
  schema "querydesk_query_approvals" do
    field :approved_at, :utc_datetime_usec

    belongs_to :organization, Organization
    belongs_to :query, Query
    belongs_to :approving_user, User
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:approved_at, :approving_user_id, :query_id, :organization_id])
    |> validate_required([:approved_at, :approving_user_id, :query_id, :organization_id])
    |> unique_constraint([:approving_user_id, :query_id])
  end
end
