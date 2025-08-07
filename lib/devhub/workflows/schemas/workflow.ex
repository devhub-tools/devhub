defmodule Devhub.Workflows.Schemas.Workflow do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Integrations.Linear.Label
  alias Devhub.Users.Schemas.ObjectPermission
  alias Devhub.Workflows.Schemas.Step
  alias Oban.Cron.Expression

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :inputs,
             :steps,
             :trigger_linear_label,
             :cron_schedule
           ]}

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          inputs: [map()],
          organization_id: String.t(),
          cron_schedule: String.t() | nil,
          archived_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "wf"}
  schema "workflows" do
    field :name, :string
    field :archived_at, :utc_datetime
    field :trigger_linear_label_search, :string, virtual: true
    field :cron_schedule, :string

    embeds_many :inputs, Input, primary_key: false, on_replace: :delete do
      @derive {Jason.Encoder, only: [:key, :description, :type]}

      field :key, :string
      field :description, :string
      field :type, Ecto.Enum, values: [:string, :float, :integer, :boolean], default: :string
    end

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :trigger_linear_label, Label, on_replace: :nilify

    has_many :steps, Step, preload_order: [:order], on_replace: :delete, on_delete: :delete_all
    has_many :permissions, ObjectPermission, foreign_key: :workflow_id, on_replace: :delete

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [
      :name,
      :organization_id,
      :archived_at,
      :trigger_linear_label_id,
      :trigger_linear_label_search,
      :cron_schedule
    ])
    |> cast_assoc(:steps,
      with: &Step.changeset/3,
      sort_param: :step_sort,
      drop_param: :step_drop
    )
    |> cast_embed(:inputs,
      with: &input_changeset/2,
      sort_param: :input_sort,
      drop_param: :input_drop
    )
    |> validate_required([:name, :organization_id])
    |> unique_constraint([:organization_id, :name], error_key: :name)
    |> validate_cron_schedule()
  end

  defp input_changeset(input, attrs) do
    cast(input, attrs, [:key, :type, :description])
  end

  defp validate_cron_schedule(changeset) do
    with cron_schedule when is_binary(cron_schedule) <- get_field(changeset, :cron_schedule),
         {:ok, _cron} <- Expression.parse(cron_schedule) do
      changeset
    else
      {:error, _error} -> add_error(changeset, :cron_schedule, "is invalid")
      # cron schedule is not required
      nil -> changeset
    end
  end
end
