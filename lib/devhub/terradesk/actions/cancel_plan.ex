defmodule Devhub.TerraDesk.Actions.CancelPlan do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Actions.UpdatePlan

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk.Schemas.Plan

  require Logger

  @callback cancel_plan(Plan.t()) :: {:ok, Plan.t()}
  def cancel_plan(plan) do
    if is_nil(plan.workspace.agent_id) or Application.get_env(:devhub, :agent) do
      do_cancel_plan(plan)
    else
      DevhubWeb.AgentConnection.send_command(
        plan.workspace.agent_id,
        {__MODULE__, :do_cancel_plan, [plan]}
      )
    end

    with {:ok, plan} <- update_plan(plan, %{status: :canceled}) do
      notify_github_of_cancel(plan, plan.workspace.repository)
      {:ok, plan}
    end
  end

  def do_cancel_plan(plan) do
    job_name = "plan-#{plan.id}" |> String.replace("_", "-") |> String.downcase()

    Client.delete_job(job_name)
  end

  defp notify_github_of_cancel(plan, repository) do
    with %{commit_sha: commit_sha} when is_binary(commit_sha) <- plan do
      {:ok, integration} =
        Integrations.get_by(organization_id: plan.organization_id, provider: :github)

      GitHub.Client.create_check(
        integration,
        repository,
        %{
          name: "TerraDesk: #{plan.workspace.name}",
          head_sha: commit_sha,
          details_url: DevhubWeb.Endpoint.url() <> "/terradesk/plans/#{plan.id}",
          external_id: plan.id,
          conclusion: "failure",
          output: %{
            title: "Plan canceled",
            summary: "Plan for TerraDesk workspace #{plan.workspace.name}."
          }
        }
      )
    end
  end
end
