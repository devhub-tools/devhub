defmodule Devhub.Integrations.Schemas.Ical do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          link: String.t(),
          title: String.t() | nil,
          color: String.t() | nil
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "int_ical"}
  schema "integrations_ical" do
    field :link, :string
    field :title, :string
    field :color, :string

    belongs_to :organization, Devhub.Users.Schemas.Organization

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:link, :organization_id, :title, :color])
    |> validate_required([:link, :organization_id, :title, :color])
  end
end
