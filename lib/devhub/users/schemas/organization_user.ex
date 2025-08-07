defmodule Devhub.Users.Schemas.OrganizationUser do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          user_id: String.t() | nil,
          organization_id: String.t(),
          permissions: map(),
          legal_name: String.t() | nil,
          archived_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "org_usr"}
  schema "organization_users" do
    field :legal_name, :string
    field :archived_at, :utc_datetime
    field :pending, :boolean

    embeds_one :permissions, Permissions, primary_key: false, on_replace: :update do
      field :super_admin, :boolean, default: false
      field :manager, :boolean, default: false
      field :billing_admin, :boolean, default: false
    end

    belongs_to :user, Devhub.Users.User
    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :linear_user, Devhub.Integrations.Linear.User
    belongs_to :github_user, Devhub.Integrations.GitHub.User
    has_many :team_members, Devhub.Users.TeamMember, on_delete: :delete_all
    has_many :teams, through: [:team_members, :team]
    many_to_many :roles, Devhub.Users.Schemas.Role, join_through: "organization_users_roles"

    timestamps()
  end

  def changeset(org_user \\ %__MODULE__{}, attrs) do
    org_user
    |> cast(attrs, [
      :archived_at,
      :github_user_id,
      :legal_name,
      :linear_user_id,
      :organization_id,
      :pending,
      :user_id
    ])
    |> cast_embed(:permissions, required: true, with: &permissions_changeset/2)
    |> cast_assoc(:roles)
    |> validate_required([:organization_id])
    |> unique_constraint([:organization_id, :user_id])
  end

  def permissions_changeset(permissions, attrs \\ %{}) do
    cast(permissions, attrs, [:super_admin, :manager, :billing_admin])
  end
end
