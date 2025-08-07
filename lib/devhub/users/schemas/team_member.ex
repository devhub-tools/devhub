defmodule Devhub.Users.TeamMember do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @primary_key {:id, UXID, autogenerate: true, prefix: "mbr"}
  schema "team_members" do
    belongs_to :team, Devhub.Users.Team
    belongs_to :organization_user, Devhub.Users.Schemas.OrganizationUser

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, attrs) do
    model
    |> cast(attrs, [:organization_user_id, :team_id])
    |> validate_required([:organization_user_id, :team_id])
  end
end
