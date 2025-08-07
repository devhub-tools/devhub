defmodule Devhub.Workflows.Schemas.Run do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows.Schemas.Step

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @type t :: %__MODULE__{
          id: String.t(),
          status: :in_progress | :completed | :failed,
          input: map(),
          steps: [map()],
          organization_id: String.t(),
          workflow_id: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "wfr"}
  schema "workflow_runs" do
    field :status, Ecto.Enum, values: [:in_progress, :waiting_for_approval, :completed, :failed, :canceled]
    field :input, :map

    embeds_many :steps, Step, primary_key: false, on_replace: :delete do
      field :name, :string
      field :condition, :string

      field :status, Ecto.Enum,
        values: [:pending, :succeeded, :failed, :waiting_for_approval, :skipped],
        default: :pending

      field :output, :map

      polymorphic_embeds_one :action,
        types: [
          api: Step.ApiAction,
          approval: Step.ApprovalAction,
          condition: Step.ConditionAction,
          query: Step.QueryAction,
          slack: Step.SlackAction,
          slack_reply: Step.SlackReplyAction
        ],
        on_type_not_found: :raise,
        on_replace: :update

      embeds_many :approvals, Approval, primary_key: false, on_replace: :delete do
        belongs_to :organization_user, OrganizationUser, type: :string
        field :approved_at, :utc_datetime
      end

      belongs_to :workflow_step, Step, type: :string
      belongs_to :query, Devhub.QueryDesk.Schemas.Query, type: :string
    end

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :workflow, Devhub.Workflows.Schemas.Workflow

    belongs_to :triggered_by_user, Devhub.Users.User
    belongs_to :triggered_by_linear_issue, Devhub.Integrations.Linear.Issue

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [
      :status,
      :input,
      :organization_id,
      :workflow_id,
      :triggered_by_user_id,
      :triggered_by_linear_issue_id
    ])
    |> cast_embed(:steps, with: &steps_changeset/2)
    |> validate_required([:status, :input, :organization_id, :workflow_id])
  end

  def steps_changeset(steps, attrs \\ %{}) do
    steps
    |> cast(attrs, [:name, :status, :output, :workflow_step_id, :query_id, :condition])
    |> cast_embed(:approvals, with: &approvals_changeset/2)
    |> cast_polymorphic_embed(:action,
      with: [
        api: &Step.ApiAction.changeset/2,
        approval: &Step.ApprovalAction.changeset/2,
        condition: &Step.ConditionAction.changeset/2,
        query: &Step.QueryAction.changeset/2,
        slack: &Step.SlackAction.changeset/2,
        slack_reply: &Step.SlackReplyAction.changeset/2
      ],
      required: true
    )
    |> validate_required([:status, :workflow_step_id])
  end

  def approvals_changeset(approval, attrs \\ %{}) do
    attrs =
      if is_struct(attrs) do
        Map.from_struct(attrs)
      else
        attrs
      end

    approval
    |> cast(attrs, [:organization_user_id, :approved_at])
    |> validate_required([:organization_user_id, :approved_at])
  end
end
