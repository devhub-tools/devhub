defmodule Devhub.TerraDesk do
  @moduledoc false

  @behaviour Devhub.TerraDesk.Actions.ApprovePlan
  @behaviour Devhub.TerraDesk.Actions.CancelPlan
  @behaviour Devhub.TerraDesk.Actions.CreatePlan
  @behaviour Devhub.TerraDesk.Actions.CreateWorkspace
  @behaviour Devhub.TerraDesk.Actions.DeleteWorkspace
  @behaviour Devhub.TerraDesk.Actions.GetPlan
  @behaviour Devhub.TerraDesk.Actions.GetRecentPlans
  @behaviour Devhub.TerraDesk.Actions.GetWorkspace
  @behaviour Devhub.TerraDesk.Actions.GetWorkspaces
  @behaviour Devhub.TerraDesk.Actions.HandleWebhook
  @behaviour Devhub.TerraDesk.Actions.InsertOrUpdateWorkspace
  @behaviour Devhub.TerraDesk.Actions.ListSchedules
  @behaviour Devhub.TerraDesk.Actions.ListTerraformResources
  @behaviour Devhub.TerraDesk.Actions.MoveTerraformState
  @behaviour Devhub.TerraDesk.Actions.PlanChanges
  @behaviour Devhub.TerraDesk.Actions.PlanSummary
  @behaviour Devhub.TerraDesk.Actions.RetryPlan
  @behaviour Devhub.TerraDesk.Actions.RunApply
  @behaviour Devhub.TerraDesk.Actions.RunPlan
  @behaviour Devhub.TerraDesk.Actions.UnlockTerraformState
  @behaviour Devhub.TerraDesk.Actions.UpdatePlan

  alias Devhub.TerraDesk.Actions

  ### WORKSPACES ###

  @impl Actions.GetWorkspace
  defdelegate get_workspace(by, opts \\ []), to: Actions.GetWorkspace

  @impl Actions.GetWorkspaces
  defdelegate get_workspaces(filters \\ []), to: Actions.GetWorkspaces

  @impl Actions.CreateWorkspace
  defdelegate create_workspace(params), to: Actions.CreateWorkspace

  @impl Actions.InsertOrUpdateWorkspace
  defdelegate insert_or_update_workspace(workspace, params), to: Actions.InsertOrUpdateWorkspace

  @impl Actions.DeleteWorkspace
  defdelegate delete_workspace(workspace), to: Actions.DeleteWorkspace

  ### PLANS ###

  @impl Actions.GetRecentPlans
  defdelegate get_recent_plans(workspace), to: Actions.GetRecentPlans

  @impl Actions.GetPlan
  defdelegate get_plan(by), to: Actions.GetPlan

  @impl Actions.CreatePlan
  defdelegate create_plan(workspace, github_branch, opts \\ []), to: Actions.CreatePlan

  @impl Actions.UpdatePlan
  defdelegate update_plan(plan, params), to: Actions.UpdatePlan

  @impl Actions.ApprovePlan
  defdelegate approve_plan(plan, organization_user), to: Actions.ApprovePlan

  @impl Actions.RunPlan
  defdelegate run_plan(plan), to: Actions.RunPlan

  @impl Actions.RunApply
  defdelegate run_apply(plan), to: Actions.RunApply

  @impl Actions.CancelPlan
  defdelegate cancel_plan(plan), to: Actions.CancelPlan

  @impl Actions.RetryPlan
  defdelegate retry_plan(plan), to: Actions.RetryPlan

  @impl Actions.PlanChanges
  defdelegate plan_changes(plan), to: Actions.PlanChanges

  @impl Actions.PlanSummary
  defdelegate plan_summary(plan), to: Actions.PlanSummary

  ### TERRAFORM ###

  @impl Actions.ListTerraformResources
  defdelegate list_terraform_resources(workspace, opts \\ []), to: Actions.ListTerraformResources

  @impl Actions.UnlockTerraformState
  defdelegate unlock_terraform_state(workspace, lock_id), to: Actions.UnlockTerraformState

  @impl Actions.MoveTerraformState
  defdelegate move_terraform_state(workspace, from, to), to: Actions.MoveTerraformState

  @impl Actions.HandleWebhook
  defdelegate handle_webhook(app, payload), to: Actions.HandleWebhook

  ### DRIFT DETECTION ###

  @impl Actions.ListSchedules
  defdelegate list_schedules(opts \\ []), to: Actions.ListSchedules
end
