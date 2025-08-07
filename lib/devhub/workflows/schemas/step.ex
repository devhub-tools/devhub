defmodule Devhub.Workflows.Schemas.Step do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.ObjectPermission

  @derive {Jason.Encoder, only: [:id, :name, :order, :action, :permissions, :condition]}

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          order: integer(),
          condition: String.t() | nil,
          workflow_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "wfs"}
  schema "workflow_steps" do
    field :order, :integer
    field :name, :string
    field :condition, :string

    polymorphic_embeds_one :action,
      types: [
        api: __MODULE__.ApiAction,
        approval: __MODULE__.ApprovalAction,
        condition: __MODULE__.ConditionAction,
        query: __MODULE__.QueryAction,
        slack: __MODULE__.SlackAction,
        slack_reply: __MODULE__.SlackReplyAction
      ],
      on_type_not_found: :raise,
      on_replace: :update

    belongs_to :workflow, Devhub.Workflows.Schemas.Workflow

    has_many :permissions, ObjectPermission, foreign_key: :workflow_step_id, on_replace: :delete

    timestamps()
  end

  def changeset(schema, attrs, order) do
    schema
    |> cast(attrs, [:workflow_id, :name, :condition])
    |> unique_constraint([:workflow_id, :name], error_key: :name, message: "step names must be unique")
    |> validate_format(:name, ~r/^[a-z0-9\-]+$/, message: "can only contain lowercase letters, underscores, or hyphens")
    |> put_change(:order, order)
    |> cast_polymorphic_embed(:action,
      with: [
        api: &__MODULE__.ApiAction.changeset/2,
        approval: &__MODULE__.ApprovalAction.changeset/2,
        condition: &__MODULE__.ConditionAction.changeset/2,
        query: &__MODULE__.QueryAction.changeset/2,
        slack: &__MODULE__.SlackAction.changeset/2,
        slack_reply: &__MODULE__.SlackReplyAction.changeset/2
      ],
      required: true
    )
    |> cast_assoc(:permissions,
      with: &ObjectPermission.changeset/2,
      sort_param: :permission_sort,
      drop_param: :permission_drop
    )
  end
end
