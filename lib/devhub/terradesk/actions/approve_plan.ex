defmodule Devhub.TerraDesk.Actions.ApprovePlan do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Permissions
  alias Devhub.TerraDesk.Schemas.Plan
  alias Devhub.Users.Schemas.OrganizationUser

  @callback approve_plan(Plan.t(), OrganizationUser.t()) :: {:ok, Plan.t()} | {:error, String.t()}
  def approve_plan(plan, organization_user) do
    if Permissions.can?(:approve, plan.workspace, organization_user) do
      do_approve_plan(plan, organization_user)
    else
      {:error, "You do not have permission to approve this plan"}
    end
  end

  defp do_approve_plan(plan, organization_user) do
    existing_approvals =
      Enum.map(plan.approvals || [], &%{organization_user_id: &1.organization_user_id, approved_at: &1.approved_at})

    approvals =
      Enum.uniq_by(
        [%{organization_user_id: organization_user.id, approved_at: DateTime.utc_now()} | existing_approvals],
        & &1.organization_user_id
      )

    plan
    |> Plan.update_changeset(%{approvals: approvals})
    |> Devhub.Repo.update()
  end
end
