defmodule Devhub.TerraDesk.Actions.RunApply do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Actions.UpdatePlan
  import Devhub.TerraDesk.Utils.BuildEnvVars
  import Devhub.TerraDesk.Utils.Container
  import Devhub.TerraDesk.Utils.JobSpec
  import Devhub.TerraDesk.Utils.StreamLog

  alias Devhub.Integrations
  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  require Logger

  @callback run_apply(Plan.t()) :: {:ok, Plan.t()}
  def run_apply(plan) do
    {:ok, %{status: :planned} = plan} = TerraDesk.get_plan(id: plan.id)

    if length(plan.approvals || []) >= plan.workspace.required_approvals do
      {:ok, plan} = update_plan(plan, %{status: :running})

      {:ok, integration} =
        Integrations.get_by(organization_id: plan.organization_id, provider: :github)

      internal_token = Phoenix.Token.sign(DevhubWeb.Endpoint, "internal", %{plan_id: plan.id})

      env = [{"INTERNAL_TOKEN", internal_token} | build_env_vars(plan.workspace, integration)]

      result =
        if is_nil(plan.workspace.agent_id) or Application.get_env(:devhub, :agent) do
          do_run_apply(plan, env)
        else
          DevhubWeb.AgentConnection.send_command(
            plan.workspace.agent_id,
            {__MODULE__, :do_run_apply, [plan, env]}
          )
        end

      case result do
        {:ok, updates} ->
          update_plan(plan, updates)

        {:error, error} ->
          Logger.error("Failed to run plan: #{inspect(error)}")
          update_plan(plan, %{status: :failed, output: nil})
      end
    else
      raise "Plan requires more approvals"
    end
  end

  def do_run_apply(plan, env) do
    secret_name = plan.workspace.id |> String.replace("_", "-") |> String.downcase()

    with :ok <- Client.create_or_update_secret(secret_name, env),
         {:ok, job_name} <- create_k8s_job(plan),
         {:ok, %{"metadata" => %{"name" => pod}}} <- Client.find_pod_for_job(job_name),
         {:ok, _git_log} <- stream_log(plan.id, pod, "git"),
         {:ok, _init_log} <- stream_log(plan.id, pod, "init"),
         {:ok, apply_log} <- stream_log(plan.id, pod, "apply") do
      {:ok, job_status} = Client.get_finished_job_status(pod)

      status =
        cond do
          job_status == "Succeeded" -> :applied
          job_status == "Failed" -> :failed
        end

      {:ok,
       %{
         status: status,
         # clear output now that it has been applied
         output: nil,
         log: plan.log <> apply_log
       }}
    else
      error ->
        Logger.error("Failed to run apply: #{inspect(error)}")
        {:error, error}
    end
  end

  defp create_k8s_job(plan) do
    job_name = "apply-#{plan.id}" |> String.replace("_", "-") |> String.downcase()
    secret_name = plan.workspace.id |> String.replace("_", "-") |> String.downcase()
    host = Application.get_env(:devhub, :agent_config)["endpoint"] || DevhubWeb.Endpoint.url()

    job_spec =
      job_spec(job_name, plan.workspace, plan.github_branch,
        init_containers: [
          container(
            %{
              "name" => "download-plan",
              "image" => "alpine/curl:8.11.1",
              "args" => [
                "-H",
                "x-internal-key: $(INTERNAL_TOKEN)",
                "-o",
                "/workspace/plan.out",
                "#{host}/api/internal/terradesk/download-plan"
              ]
            },
            secret_name
          )
        ],
        containers: [
          container(
            %{
              "name" => "apply",
              "image" => plan.workspace.docker_image,
              "args" => ["apply", "/workspace/plan.out"],
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
        ]
      )

    with :ok <- Client.create_job(job_spec) do
      {:ok, job_name}
    end
  end
end
