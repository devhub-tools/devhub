defmodule Devhub.Integrations.Linear.Project do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          archived_at: DateTime.t() | nil,
          canceled_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          created_at: DateTime.t() | nil,
          external_id: String.t(),
          name: String.t(),
          status: String.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lin_prj"}
  schema "linear_projects" do
    field :archived_at, :utc_datetime
    field :canceled_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :created_at, :utc_datetime
    field :external_id, :string
    field :name, :string
    field :status, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [
      :organization_id,
      :archived_at,
      :canceled_at,
      :completed_at,
      :created_at,
      :external_id,
      :name,
      :status
    ])
    |> validate_required([:organization_id, :external_id, :name])
    |> unique_constraint([:organization_id, :external_id])
  end
end
