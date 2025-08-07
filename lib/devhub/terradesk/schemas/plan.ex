defmodule Devhub.TerraDesk.Schemas.Plan do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.TerraDesk.Schemas.Schedule
  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.Types.EncryptedBinary
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Users.User
  alias Ecto.Association.NotLoaded

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @type t :: %__MODULE__{
          id: String.t(),
          github_branch: String.t(),
          status: :queued | :running | :failed | :planned | :applied | :canceled,
          output: binary() | nil,
          log: String.t() | nil,
          commit_sha: String.t() | nil,
          targeted_resources: [String.t()],
          workspace: Workspace.t(),
          user: User.t() | NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          schedule: Schedule.t() | NotLoaded.t(),
          attempt: integer()
        }

  @redact Application.compile_env(:devhub, :compile_env) != :test

  @primary_key {:id, UXID, autogenerate: true, prefix: "tfp"}
  schema "terraform_plans" do
    field :github_branch, :string
    field :commit_sha, :string
    field :output, EncryptedBinary, redact: @redact
    field :log, EncryptedBinary, redact: @redact
    field :targeted_resources, {:array, :string}, default: []
    field :attempt, :integer, default: 1

    field :status, Ecto.Enum,
      values: [:queued, :running, :failed, :planned, :applied, :canceled],
      default: :queued

    embeds_many :approvals, Approval, primary_key: false, on_replace: :delete do
      belongs_to :organization_user, OrganizationUser, type: :string
      field :approved_at, :utc_datetime
    end

    belongs_to :organization, Organization
    belongs_to :workspace, Workspace
    belongs_to :user, User
    belongs_to :schedule, Schedule

    timestamps()
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:github_branch, :commit_sha, :targeted_resources, :schedule_id])
    |> put_assoc(:workspace, params.workspace)
    |> put_assoc(:user, params.user)
    |> put_assoc(:organization, params.organization)
    |> validate_required([:github_branch, :organization])
    |> unique_constraint([:workspace_id, :commit_sha])
  end

  def update_changeset(plan, params) do
    plan
    |> cast(params, [:status, :output, :log, :attempt])
    |> cast_embed(:approvals, with: &approvals_changeset/2)
    |> validate_required([:status])
    |> unique_constraint([:workspace_id, :status])
  end

  def approvals_changeset(approvals, attrs \\ %{}) do
    approvals
    |> cast(attrs, [:organization_user_id, :approved_at])
    |> validate_required([:organization_user_id, :approved_at])
  end
end
