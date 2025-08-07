defmodule Devhub.Integrations.Linear.Label do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :external_id,
             :name,
             :color,
             :type,
             :is_group
           ]}

  @type t :: %__MODULE__{
          id: String.t(),
          external_id: String.t(),
          name: String.t() | nil,
          color: String.t() | nil,
          type: String.t(),
          is_group: boolean()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lin_lbl"}
  schema "linear_labels" do
    field :external_id, :string
    field :name, :string
    field :color, :string
    field :type, Ecto.Enum, values: [:feature, :bug, :tech_debt], default: :feature
    field :is_group, :boolean, default: false

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :parent_label, Devhub.Integrations.Linear.Label, foreign_key: :parent_label_id
    belongs_to :team, Devhub.Integrations.Linear.Team
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:organization_id, :external_id, :name, :color, :is_group, :type])
    |> validate_required([:organization_id, :external_id, :type])
    |> unique_constraint([:organization_id, :external_id])
    |> update_change(:color, fn
      "#" <> _rest = color -> color
      color -> "##{color}"
    end)
    |> put_assoc(:parent_label, attrs.parent_label)
    |> put_assoc(:team, attrs.team)
  end

  def form_changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [:organization_id, :external_id, :name, :color, :type])
    |> validate_required([:organization_id, :external_id, :type])
    |> unique_constraint([:organization_id, :external_id])
    |> update_change(:color, fn
      "#" <> _rest = color -> color
      color -> "##{color}"
    end)
  end
end
