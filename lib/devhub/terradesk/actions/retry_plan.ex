defmodule Devhub.TerraDesk.Actions.RetryPlan do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Actions.UpdatePlan

  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk.Jobs.RunPlan
  alias Devhub.TerraDesk.Schemas.Plan

  require Logger

  @callback retry_plan(Plan.t()) :: {:ok, Plan.t()}
  def retry_plan(plan) do
    if is_nil(plan.workspace.agent_id) or Application.get_env(:devhub, :agent) do
      cancel_job(plan)
    else
      DevhubWeb.AgentConnection.send_command(
        plan.workspace.agent_id,
        {__MODULE__, :cancel_job, [plan]}
      )
    end

    with {:ok, plan} <- update_plan(plan, %{status: :queued, attempt: plan.attempt + 1}) do
      %{id: plan.id} |> RunPlan.new(queue: :terradesk) |> Oban.insert()
      {:ok, plan}
    end
  end

  def cancel_job(plan) do
    job_name = "plan-#{plan.id}" |> String.replace("_", "-") |> String.downcase()

    Client.delete_job(job_name)
  end
end
