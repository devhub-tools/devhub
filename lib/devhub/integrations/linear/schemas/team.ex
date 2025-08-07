defmodule Devhub.Integrations.Linear.Team do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          external_id: String.t() | nil,
          name: String.t() | nil,
          key: String.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lin_tm"}
  schema "linear_teams" do
    field :external_id, :string
    field :name, :string
    field :key, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :team, Devhub.Users.Team
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:organization_id, :external_id, :name, :key, :team_id])
    |> unique_constraint([:organization_id, :external_id])
  end
end
