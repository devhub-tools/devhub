defmodule Devhub.QueryDesk.Schemas.DataProtectionPolicy do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "dpp"}
  schema "data_protection_policies" do
    field :name, :string
    field :description, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :database, Devhub.QueryDesk.Schemas.Database

    has_many :columns, Devhub.QueryDesk.Schemas.DataProtectionColumn, foreign_key: :policy_id

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [
      :name,
      :description,
      :organization_id,
      :database_id
    ])
    |> validate_required([
      :name,
      :organization_id,
      :database_id
    ])
    |> unique_constraint([:organization_id, :database_id, :name], error_key: :name)
  end
end
