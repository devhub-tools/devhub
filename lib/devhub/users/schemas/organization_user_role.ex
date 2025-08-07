defmodule Devhub.Users.Schemas.OrganizationUserRole do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @primary_key {:id, UXID, autogenerate: true, prefix: "our"}
  schema "organization_users_roles" do
    belongs_to :role, Devhub.Users.Schemas.Role
    belongs_to :organization_user, Devhub.Users.Schemas.OrganizationUser

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [:organization_user_id, :role_id])
    |> validate_required([:organization_user_id, :role_id])
  end
end
