defmodule Devhub.Users.Schemas.ObjectPermission do
  @moduledoc false
  use Devhub.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :permission, :organization_user_id, :role_id]}

  @primary_key {:id, UXID, autogenerate: true, prefix: "perm"}
  schema "object_permissions" do
    field :permission, Ecto.Enum, values: [:read, :trigger, :write, :approve, :admin]

    # assigned to
    belongs_to :organization_user, Devhub.Users.Schemas.OrganizationUser
    belongs_to :role, Devhub.Users.Schemas.Role

    # granted resources
    belongs_to :dashboard, Devhub.Dashboards.Schemas.Dashboard
    belongs_to :database, Devhub.QueryDesk.Schemas.Database
    belongs_to :terraform_workspace, Devhub.TerraDesk.Schemas.Workspace
    belongs_to :workflow, Devhub.Workflows.Schemas.Workflow
    belongs_to :workflow_step, Devhub.Workflows.Schemas.Step
    belongs_to :shared_query, Devhub.QueryDesk.Schemas.SharedQuery

    # extra associations
    belongs_to :data_protection_policy, Devhub.QueryDesk.Schemas.DataProtectionPolicy

    timestamps()
  end

  def changeset(schema \\ %__MODULE__{}, attrs) do
    schema
    |> cast(attrs, [
      :organization_user_id,
      :role_id,
      :permission,
      :database_id,
      :dashboard_id,
      :data_protection_policy_id,
      :terraform_workspace_id,
      :workflow_id,
      :workflow_step_id
    ])
    |> validate_required([:permission])
    |> validate_assignment()
  end

  def details(%{dashboard_id: id} = permission) when is_binary(id) do
    %{
      icon: "hero-chart-bar",
      name: permission.dashboard.name,
      link: "/dashboards/#{id}",
      type: "Dashboard",
      permission: "View"
    }
  end

  def details(%{database_id: id} = permission) when is_binary(id) do
    %{
      icon: "devhub-querydesk",
      name: permission.database.name || "(New database)",
      link: "/querydesk/databases/#{id}",
      type: "Database",
      permission: (permission.permission == :approve && "Approver") || "Run queries"
    }
  end

  def details(%{terraform_workspace_id: id} = permission) when is_binary(id) do
    %{
      icon: "devhub-terradesk",
      name: permission.terraform_workspace.name,
      link: "/terradesk/workspaces/#{id}/settings",
      type: "Terraform Workspace",
      permission: "Approver"
    }
  end

  def details(%{workflow_step_id: id} = permission) when is_binary(id) do
    %{
      icon: "hero-arrow-path-rounded-square",
      name: permission.workflow_step.workflow.name,
      link: "/workflows/#{permission.workflow_step.workflow_id}",
      type: "Workflow",
      permission: "Approver"
    }
  end

  def details(_other), do: nil

  defp validate_assignment(changeset) do
    organization_user_id = get_field(changeset, :organization_user_id)
    role_id = get_field(changeset, :role_id)

    organization_user_id_set? = not is_nil(organization_user_id) and organization_user_id != ""
    role_id_set? = not is_nil(role_id) and role_id != ""

    cond do
      organization_user_id_set? and role_id_set? ->
        add_error(changeset, :organization_user_id, "must have either an organization user or role assigned")

      organization_user_id_set? ->
        changeset

      role_id_set? ->
        changeset

      true ->
        add_error(changeset, :organization_user_id, "must have either an organization user or role assigned")
    end
  end
end
