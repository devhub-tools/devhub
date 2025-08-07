defmodule Devhub.TerraDesk.Actions.RunPlan do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Actions.UpdatePlan
  import Devhub.TerraDesk.Utils.BuildEnvVars
  import Devhub.TerraDesk.Utils.Container
  import Devhub.TerraDesk.Utils.JobSpec
  import Devhub.TerraDesk.Utils.StreamLog

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.Integrations.Slack
  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Plan

  require Logger

  @callback run_plan(Plan.t()) :: {:ok, Plan.t()}
  def run_plan(plan) do
    plan = Repo.preload(plan, workspace: [:env_vars, :secrets, :workload_identity])

    if Devhub.cloud_hosted?() and is_nil(plan.workspace.agent_id) do
      raise "Agent is required for cloud hosted plans"
    end

    {:ok, plan} = update_plan(plan, %{status: :running})

    Logger.info("Starting plan #{plan.id}")

    {:ok, integration} =
      Integrations.get_by(organization_id: plan.organization_id, provider: :github)

    notify_github_of_start(plan, integration, plan.workspace.repository)

    internal_token = Phoenix.Token.sign(DevhubWeb.Endpoint, "internal", %{plan_id: plan.id})

    env = [{"INTERNAL_TOKEN", internal_token} | build_env_vars(plan.workspace, integration)]

    result =
      if is_nil(plan.workspace.agent_id) or Application.get_env(:devhub, :agent) do
        do_run_plan(plan, env)
      else
        DevhubWeb.AgentConnection.send_command(
          plan.workspace.agent_id,
          {__MODULE__, :do_run_plan, [plan, env]}
        )
      end

    updates =
      case result do
        {:ok, updates} ->
          updates

        {:error, error} ->
          Logger.error("Failed to run plan: #{inspect(error)}")
          %{status: :failed}
      end

    with {:ok, plan} <- update_plan(plan, updates) do
      notify_github_of_finish(plan, integration, plan.workspace.repository)
      maybe_notify_slack_of_finish(plan)
      {:ok, plan}
    end
  end

  def do_run_plan(plan, env) do
    secret_name = plan.workspace.id |> String.replace("_", "-") |> String.downcase()

    with :ok <- Client.create_or_update_secret(secret_name, env),
         {:ok, job_name} <- create_k8s_job(plan),
         {:ok, %{"metadata" => %{"name" => pod}}} <- Client.find_pod_for_job(job_name),
         {:ok, git_log} <- stream_log(plan.id, pod, "git"),
         {:ok, init_log} <- stream_log(plan.id, pod, "init", git_log),
         {:ok, plan_log} <- stream_log(plan.id, pod, "plan", init_log) do
      {:ok, job_status} = Client.get_finished_job_status(pod)

      status =
        cond do
          String.contains?(plan_log, "No changes.") -> :applied
          job_status == "Succeeded" -> :planned
          job_status == "Failed" -> :failed
        end

      {:ok,
       %{
         status: status,
         log: String.trim(plan_log)
       }}
    else
      {:error, :failed_to_get_log, log_acc} ->
        {:ok,
         %{
           status: :failed,
           log: String.trim(log_acc)
         }}

      error ->
        error
    end
  end

  defp create_k8s_job(plan) do
    job_name = "plan-#{plan.id}-#{plan.attempt}" |> String.replace("_", "-") |> String.downcase()
    secret_name = plan.workspace.id |> String.replace("_", "-") |> String.downcase()
    host = Application.get_env(:devhub, :agent_config)["endpoint"] || DevhubWeb.Endpoint.url()

    target_args =
      plan.targeted_resources
      |> Enum.map(&["-target", &1])
      |> List.flatten()

    job_spec =
      job_spec(job_name, plan.workspace, plan.github_branch,
        init_containers: [
          container(
            %{
              "name" => "plan",
              "image" => plan.workspace.docker_image,
              "args" => ["plan", "--input=false", "--out", "plan.out" | target_args],
              "workingDir" => "/workspace/#{plan.workspace.path}",
              "resources" => %{
                "requests" => %{
                  "cpu" => plan.workspace.cpu_requests,
                  "memory" => plan.workspace.memory_requests
                }
              }
            },
            secret_name
          )
        ],
        containers: [
          container(
            %{
              "name" => "upload-plan",
              "image" => "alpine/curl:8.11.1",
              "args" => [
                "-X",
                "POST",
                "-H",
                "x-internal-key: $(INTERNAL_TOKEN)",
                "-F",
                "plan.out=@/workspace/#{plan.workspace.path}/plan.out",
                "#{host}/api/internal/terradesk/upload-plan"
              ]
            },
            secret_name
          )
        ]
      )

    with :ok <- Client.create_job(job_spec) do
      {:ok, job_name}
    end
  end

  defp notify_github_of_start(plan, integration, repository) do
    with %{commit_sha: commit_sha} when is_binary(commit_sha) <- plan do
      GitHub.Client.create_check(
        integration,
        repository,
        %{
          name: "TerraDesk: #{plan.workspace.name}",
          head_sha: commit_sha,
          details_url: DevhubWeb.Endpoint.url() <> "/terradesk/plans/#{plan.id}",
          external_id: plan.id,
          status: "in_progress"
        }
      )
    end
  end

  defp notify_github_of_finish(plan, integration, repository) do
    with %{commit_sha: commit_sha} when is_binary(commit_sha) <- plan do
      summary = Devhub.TerraDesk.plan_summary(plan)

      title =
        case plan.status do
          :planned -> "#{summary.add} to add, #{summary.change} to change, #{summary.destroy} to destroy"
          :applied -> "No changes"
          :failed -> "Plan failed"
        end

      GitHub.Client.create_check(
        integration,
        repository,
        %{
          name: "TerraDesk: #{plan.workspace.name}",
          head_sha: commit_sha,
          details_url: DevhubWeb.Endpoint.url() <> "/terradesk/plans/#{plan.id}",
          external_id: plan.id,
          conclusion: (plan.status in [:planned, :applied] && "success") || "failure",
          output: %{
            title: title,
            summary: "Plan for TerraDesk workspace #{plan.workspace.name}."
          }
        }
      )
    end
  end

  defp maybe_notify_slack_of_finish(plan) do
    with %{schedule: %{slack_channel: slack_channel}} when is_binary(slack_channel) <- Repo.preload(plan, :schedule),
         %{add: add, change: change, destroy: destroy} when add > 0 or change > 0 or destroy > 0 <-
           Devhub.TerraDesk.plan_summary(plan) do
      message =
        "Drift detection run for `#{plan.workspace.name}` finished: #{add} to add, #{change} to change, #{destroy} to destroy"

      Slack.post_message(plan.organization_id, slack_channel, %{
        blocks: [
          %{type: "section", text: %{type: "mrkdwn", text: message}},
          %{
            type: "section",
            text: %{
              type: "mrkdwn",
              text: "<#{DevhubWeb.Endpoint.url()}/terradesk/plans/#{plan.id}|Review plan>"
            }
          }
        ]
      })
    end
  end
end
