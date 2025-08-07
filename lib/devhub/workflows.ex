defmodule Devhub.Workflows do
  @moduledoc false
  @behaviour Devhub.Workflows.Actions.ApproveStep
  @behaviour Devhub.Workflows.Actions.CancelRun
  @behaviour Devhub.Workflows.Actions.Continue
  @behaviour Devhub.Workflows.Actions.CreateWorkflow
  @behaviour Devhub.Workflows.Actions.DeleteWorkflow
  @behaviour Devhub.Workflows.Actions.GetRun
  @behaviour Devhub.Workflows.Actions.GetWorkflow
  @behaviour Devhub.Workflows.Actions.ListRuns
  @behaviour Devhub.Workflows.Actions.ListWorkflows
  @behaviour Devhub.Workflows.Actions.MyWaitingWorkflows
  @behaviour Devhub.Workflows.Actions.PreloadRun
  @behaviour Devhub.Workflows.Actions.ReplaceVariables
  @behaviour Devhub.Workflows.Actions.RunWorkflow
  @behaviour Devhub.Workflows.Actions.UpdateWorkflow

  alias Devhub.Workflows.Actions

  @impl Actions.CreateWorkflow
  defdelegate create_workflow(params), to: Actions.CreateWorkflow

  @impl Actions.GetWorkflow
  defdelegate get_workflow(by), to: Actions.GetWorkflow

  @impl Actions.ListWorkflows
  defdelegate list_workflows(organization_id, filters \\ []), to: Actions.ListWorkflows

  @impl Actions.RunWorkflow
  defdelegate run_workflow(workflow, params), to: Actions.RunWorkflow

  @impl Actions.UpdateWorkflow
  defdelegate update_workflow(workflow, params), to: Actions.UpdateWorkflow

  @impl Actions.DeleteWorkflow
  defdelegate delete_workflow(workflow), to: Actions.DeleteWorkflow

  @impl Actions.MyWaitingWorkflows
  defdelegate my_waiting_workflows(organization_user), to: Actions.MyWaitingWorkflows

  ### RUNS

  @impl Actions.Continue
  defdelegate continue(run), to: Actions.Continue

  @impl Actions.ApproveStep
  defdelegate approve_step(run, step, organization_user), to: Actions.ApproveStep

  @impl Actions.GetRun
  defdelegate get_run(by), to: Actions.GetRun

  @impl Actions.PreloadRun
  defdelegate preload_run(run), to: Actions.PreloadRun

  @impl Actions.ListRuns
  defdelegate list_runs(workflow_id, opts \\ []), to: Actions.ListRuns

  @impl Actions.CancelRun
  defdelegate cancel_run(run), to: Actions.CancelRun

  @impl Actions.ReplaceVariables
  defdelegate replace_variables(input, string, steps), to: Actions.ReplaceVariables
end
