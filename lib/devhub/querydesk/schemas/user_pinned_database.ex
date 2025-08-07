defmodule Devhub.QueryDesk.Schemas.UserPinnedDatabase do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          organization_user_id: String.t(),
          database_id: String.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "upd"}
  schema "user_pinned_databases" do
    belongs_to :organization_user, Devhub.Users.Schemas.OrganizationUser
    belongs_to :database, Devhub.QueryDesk.Schemas.Database

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [:organization_user_id, :database_id])
    |> validate_required([:organization_user_id, :database_id])
  end
end
