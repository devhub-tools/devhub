defmodule Devhub.Dashboards.Schemas.Dashboard do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Dashboards.Schemas.Dashboard.QueryPanel
  alias Devhub.Users.Schemas.ObjectPermission

  @derive {Jason.Encoder, only: [:id, :name, :restricted_access, :panels]}

  @type t :: %__MODULE__{
          name: String.t(),
          organization_id: String.t(),
          restricted_access: boolean(),
          archived_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "dash"}
  schema "dashboards" do
    field :restricted_access, :boolean, default: false
    field :name, :string
    field :archived_at, :utc_datetime

    belongs_to :organization, Devhub.Users.Schemas.Organization

    has_many :permissions, ObjectPermission, foreign_key: :dashboard_id, on_replace: :delete

    embeds_many :panels, Panel, primary_key: {:id, UXID, autogenerate: true, prefix: "pl"}, on_replace: :delete do
      @derive Jason.Encoder

      field :title, :string

      embeds_many :inputs, Input, on_replace: :delete do
        @derive Jason.Encoder

        field :key, :string
        field :description, :string
      end

      polymorphic_embeds_one :details,
        types: [
          query: QueryPanel
        ],
        on_type_not_found: :raise,
        on_replace: :update
    end

    timestamps()
  end

  def changeset(dashboard \\ %__MODULE__{}, params) do
    dashboard
    |> cast(params, [:name, :organization_id, :restricted_access])
    |> cast_assoc(:permissions,
      with: &ObjectPermission.changeset/2,
      sort_param: :permission_sort,
      drop_param: :permission_drop
    )
    |> validate_required([:name, :organization_id, :restricted_access])
    |> unique_constraint([:organization_id, :name], error_key: :name)
    |> cast_embed(:panels,
      with: &panels_changeset/2,
      sort_param: :panel_sort,
      drop_param: :panel_drop
    )
  end

  def panels_changeset(panel, params \\ %{}) do
    params =
      params
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.replace("inputs", params["inputs"] || [])

    panel
    |> cast(params, [:title])
    |> cast_polymorphic_embed(:details,
      with: [
        query: &QueryPanel.changeset/2
      ],
      required: true
    )
    |> cast_embed(:inputs,
      with: &input_changeset/2,
      sort_param: :input_sort,
      drop_param: :input_drop
    )
    |> validate_required([:title])
  end

  defp input_changeset(input, params) do
    cast(input, params, [:key, :description])
  end
end
