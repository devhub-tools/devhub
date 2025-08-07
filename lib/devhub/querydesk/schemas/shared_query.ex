defmodule Devhub.QueryDesk.Schemas.SharedQuery do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.QueryDesk.Schemas.Database
  alias Devhub.Users.Schemas.ObjectPermission
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.User

  @type t :: %__MODULE__{
          query: String.t(),
          include_results: boolean(),
          results: map() | nil,
          restricted_access: boolean(),
          expires_at: DateTime.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "shr_qry"}
  schema "querydesk_shared_queries" do
    field :query, :string
    field :results, :binary
    field :include_results, :boolean
    field :restricted_access, :boolean, default: false
    field :expires_at, :utc_datetime
    field :expires, :boolean, default: false, virtual: true

    belongs_to :created_by_user, User
    belongs_to :database, Database
    belongs_to :organization, Organization

    has_many :permissions, ObjectPermission, foreign_key: :shared_query_id, on_replace: :delete

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :query,
      :results,
      :include_results,
      :restricted_access,
      :expires_at,
      :expires,
      :created_by_user_id,
      :database_id,
      :organization_id
    ])
    |> cast_assoc(:permissions,
      with: &ObjectPermission.changeset/2,
      sort_param: :permission_sort,
      drop_param: :permission_drop
    )
    |> validate_required([
      :query,
      :include_results,
      :restricted_access,
      :created_by_user_id,
      :database_id,
      :organization_id
    ])
  end
end
