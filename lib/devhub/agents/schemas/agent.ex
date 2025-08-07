defmodule Devhub.Agents.Schemas.Agent do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          name: String.t(),
          organization_id: String.t(),
          organization: Organization.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "agt"}
  schema "agents" do
    field :name, :string

    belongs_to :organization, Organization

    timestamps()
  end

  def create_changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, [:name, :organization_id])
    |> validate_required([:name, :organization_id])
  end

  def update_changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
