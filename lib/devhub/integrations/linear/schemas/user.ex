defmodule Devhub.Integrations.Linear.User do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          external_id: String.t() | nil,
          name: String.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lin_usr"}
  schema "linear_users" do
    field :external_id, :string
    field :name, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    has_one :organization_user, Devhub.Users.Schemas.OrganizationUser, foreign_key: :linear_user_id
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:external_id, :name, :organization_id])
    |> unique_constraint([:organization_id, :external_id])
  end
end
