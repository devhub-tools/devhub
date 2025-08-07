defmodule Devhub.Users.Schemas.Role do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :description, :managed]}

  @type t :: %__MODULE__{
          organization_id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          managed: boolean(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "role"}
  schema "roles" do
    field :name, :string
    field :description, :string
    field :managed, :boolean, default: false

    belongs_to :organization, Devhub.Users.Schemas.Organization
    has_many :permissions, Devhub.Users.Schemas.ObjectPermission
    many_to_many :organization_users, Devhub.Users.Schemas.OrganizationUser, join_through: "organization_users_roles"

    timestamps()
  end

  def changeset(role \\ %__MODULE__{}, attrs) do
    role
    |> cast(attrs, [:organization_id, :name, :description, :managed])
    |> validate_required([:organization_id, :name])
  end
end
