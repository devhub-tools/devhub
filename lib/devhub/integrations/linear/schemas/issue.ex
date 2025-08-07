defmodule Devhub.Integrations.Linear.Issue do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Workflows.Schemas.Run

  @type t :: %__MODULE__{
          id: String.t(),
          archived_at: DateTime.t() | nil,
          canceled_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          created_at: DateTime.t(),
          estimate: integer() | nil,
          external_id: String.t(),
          identifier: String.t() | nil,
          started_at: DateTime.t() | nil,
          title: String.t() | nil,
          url: String.t() | nil,
          priority: integer(),
          priority_label: String.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "lin_iss"}
  schema "linear_issues" do
    field :archived_at, :utc_datetime
    field :canceled_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :created_at, :utc_datetime
    field :estimate, :integer
    field :external_id, :string
    field :identifier, :string
    field :started_at, :utc_datetime
    field :title, :string
    field :url, :string
    field :priority, :integer
    field :priority_label, :string

    embeds_one :state, State do
      field :color, :string
      field :name, :string
      field :type, :string
    end

    belongs_to :organization, Devhub.Users.Schemas.Organization
    belongs_to :linear_team, Devhub.Integrations.Linear.Team
    belongs_to :linear_user, Devhub.Integrations.Linear.User

    has_many :workflow_runs, Run, foreign_key: :triggered_by_linear_issue_id

    many_to_many :labels, Devhub.Integrations.Linear.Label,
      join_through: "linear_issues_labels",
      on_replace: :delete,
      unique: true
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [
      :organization_id,
      :linear_user_id,
      :linear_team_id,
      :archived_at,
      :canceled_at,
      :completed_at,
      :created_at,
      :estimate,
      :external_id,
      :identifier,
      :started_at,
      :title,
      :url,
      :priority,
      :priority_label
    ])
    |> cast_embed(:state, with: &state_changeset/2)
    |> validate_required([:organization_id, :external_id])
    |> unique_constraint([:organization_id, :external_id])
  end

  def labels_changeset(schema, labels) do
    schema
    |> cast(%{}, [])
    |> put_assoc(:labels, labels)
  end

  def state_changeset(state, attrs \\ %{}) do
    cast(state, attrs, [:id, :color, :name, :type])
  end
end
