defmodule Devhub.Users.Team do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          name: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "team"}
  schema "teams" do
    field :name, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization
    has_many :team_members, Devhub.Users.TeamMember, on_delete: :delete_all
    many_to_many :users, Devhub.Users.User, join_through: "team_members"

    timestamps()
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :organization_id])
    |> validate_required([:name, :organization_id])
  end
end
