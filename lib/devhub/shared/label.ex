defmodule Devhub.Shared.Schemas.Label do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.Organization

  @type t :: %__MODULE__{
          color: String.t(),
          name: String.t(),
          organization_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "la"}
  schema "labels" do
    field :color, :string
    field :name, :string

    belongs_to :organization, Organization

    timestamps()
  end

  def changeset(struct \\ %__MODULE__{}, params) do
    color =
      Enum.map_join(
        [Enum.random(55..255), Enum.random(55..255), Enum.random(55..255)],
        "",
        &Integer.to_string(&1, 16)
      )

    params = Map.put_new(params, "color", color)

    struct
    |> cast(params, [:color, :name, :organization_id])
    |> unique_constraint([:organization_id, :name])
    |> validate_required([:color, :name, :organization_id])
    |> update_change(:color, fn
      "#" <> _rest = color -> color
      color -> "##{color}"
    end)
    |> validate_format(:color, ~r/^#([0-9a-fA-F]{6})$/)
  end
end
