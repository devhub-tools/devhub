defmodule Devhub.TerraDesk.Schemas.Workspace do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  alias Devhub.Agents.Schemas.Agent
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.TerraDesk.Schemas.EnvVar
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.TerraDesk.Schemas.Schedule
  alias Devhub.TerraDesk.Schemas.Secret
  alias Devhub.TerraDesk.Schemas.WorkloadIdentity
  alias Devhub.Users.Schemas.ObjectPermission
  alias Devhub.Users.Schemas.Organization
  alias Ecto.Association.NotLoaded

  @derive {LiveSync.Watch, [subscription_key: :organization_id]}

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :repository,
             :path,
             :init_args,
             :run_plans_automatically,
             :required_approvals,
             :docker_image,
             :cpu_requests,
             :memory_requests,
             :env_vars,
             :secrets,
             :workload_identity,
             :agent_id,
             :inserted_at,
             :updated_at
           ]}

  @type t :: %__MODULE__{
          name: String.t(),
          path: String.t(),
          init_args: String.t() | nil,
          run_plans_automatically: boolean(),
          required_approvals: integer(),
          docker_image: String.t(),
          cpu_requests: String.t(),
          memory_requests: String.t(),
          organization: Organization.t() | NotLoaded.t(),
          agent: Agent.t() | nil | NotLoaded.t(),
          repository: Repository.t() | NotLoaded.t(),
          workload_identity: WorkloadIdentity.t() | nil | NotLoaded.t(),
          latest_plan: Plan.t() | nil | NotLoaded.t(),
          env_vars: [EnvVar.t()] | NotLoaded.t(),
          secrets: [Secret.t()] | NotLoaded.t()
        }

  @primary_key {:id, UXID, autogenerate: true, prefix: "tfws"}
  schema "terraform_workspaces" do
    field :name, :string
    field :init_args, :string
    field :path, :string
    field :run_plans_automatically, :boolean, default: false
    field :required_approvals, :integer, default: 0
    field :docker_image, :string, default: "hashicorp/terraform:1.9"
    field :cpu_requests, :string, default: "100m"
    field :memory_requests, :string, default: "512M"

    belongs_to :organization, Organization
    belongs_to :agent, Agent
    belongs_to :repository, Repository
    has_one :workload_identity, WorkloadIdentity, on_replace: :delete, on_delete: :delete_all
    has_one :latest_plan, Plan
    has_many :secrets, Secret, on_replace: :delete, on_delete: :delete_all
    has_many :env_vars, EnvVar, on_replace: :delete, on_delete: :delete_all

    has_many :permissions, ObjectPermission,
      foreign_key: :terraform_workspace_id,
      on_replace: :delete,
      on_delete: :delete_all

    many_to_many :schedules, Schedule, join_through: "terraform_workspace_schedules"

    timestamps()
  end

  def changeset(workspace \\ %__MODULE__{}, params) do
    workspace
    |> cast(params, [
      :name,
      :init_args,
      :path,
      :run_plans_automatically,
      :required_approvals,
      :docker_image,
      :cpu_requests,
      :memory_requests,
      :agent_id,
      :organization_id,
      :repository_id
    ])
    |> cast_workload_identity()
    |> cast_assoc(:secrets,
      with: &Secret.changeset/2,
      sort_param: :secret_sort,
      drop_param: :secret_drop
    )
    |> cast_assoc(:env_vars,
      with: &EnvVar.changeset/2,
      sort_param: :env_var_sort,
      drop_param: :env_var_drop
    )
    |> cast_assoc(:permissions,
      with: &ObjectPermission.changeset/2,
      sort_param: :permission_sort,
      drop_param: :permission_drop
    )
    |> validate_required([
      :name,
      :repository_id,
      :docker_image,
      :cpu_requests,
      :memory_requests
    ])
    |> foreign_key_constraint(:repository_id)
    |> foreign_key_constraint(:agent_id)
  end

  defp cast_workload_identity(changeset) do
    organization_id = get_field(changeset, :organization_id)

    cast_assoc(changeset, :workload_identity,
      with: fn schema, params ->
        WorkloadIdentity.changeset(
          schema,
          Map.put(params, "organization_id", organization_id)
        )
      end
    )
  end
end
