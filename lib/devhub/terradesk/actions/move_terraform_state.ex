defmodule Devhub.TerraDesk.Actions.MoveTerraformState do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Utils.BuildEnvVars
  import Devhub.TerraDesk.Utils.Container
  import Devhub.TerraDesk.Utils.JobSpec
  import Devhub.TerraDesk.Utils.StreamLog

  alias Devhub.Integrations
  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk.Schemas.Workspace

  require Logger

  @callback move_terraform_state(Workspace.t(), String.t(), String.t()) :: :ok | :error
  def move_terraform_state(workspace, from, to) do
    workspace = Devhub.Repo.preload(workspace, [:repository])

    {:ok, integration} =
      Integrations.get_by(organization_id: workspace.organization_id, provider: :github)

    env = build_env_vars(workspace, integration)

    if is_nil(workspace.agent_id) or Application.get_env(:devhub, :agent) do
      do_move_terraform_state(workspace, env, from, to)
    else
      DevhubWeb.AgentConnection.send_command(
        workspace.agent_id,
        {__MODULE__, :do_move_terraform_state, [workspace, env, from, to]}
      )
    end
  end

  def do_move_terraform_state(workspace, env, from, to) do
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    with :ok <- Client.create_or_update_secret(secret_name, env),
         {:ok, job_name} <- create_k8s_job(workspace, from, to),
         {:ok, %{"metadata" => %{"name" => pod}}} <- Client.find_pod_for_job(job_name),
         {:ok, _log} <- stream_log(workspace.id, pod, "git"),
         {:ok, _log} <- stream_log(workspace.id, pod, "init"),
         {:ok, _log} <- stream_log(workspace.id, pod, "move") do
      {:ok, phase} = Client.get_finished_job_status(pod)

      cond do
        phase == "Succeeded" -> :ok
        phase == "Failed" -> :error
      end
    else
      error ->
        Logger.error("Failed to move terraform state: #{inspect(error)}")
        :error
    end
  end

  defp create_k8s_job(workspace, from, to) do
    timestamp = Calendar.strftime(DateTime.utc_now(), "%H%M%S")

    job_name =
      "move-#{timestamp}-#{from}"
      |> String.replace(~r/[^a-zA-Z0-9-.]/, "-")
      |> String.downcase()
      |> String.slice(0, 63)
      |> String.trim_trailing("-")
      |> String.trim_trailing(".")

    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    job_spec =
      job_spec(job_name, workspace, workspace.repository.default_branch,
        containers: [
          container(
            %{
              "name" => "move",
              "image" => workspace.docker_image,
              "args" => ["state", "mv", from, to],
              "workingDir" => "/workspace/#{workspace.path}"
            },
            secret_name
          )
        ]
      )

    :ok = Client.create_job(job_spec)
    {:ok, job_name}
  rescue
    error -> {:error, error}
  end
end
