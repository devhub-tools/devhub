defmodule Devhub.TerraDesk.Actions.UnlockTerraformState do
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

  @callback unlock_terraform_state(Workspace.t(), String.t()) :: :ok | :error
  def unlock_terraform_state(workspace, lock_id) do
    workspace = Devhub.Repo.preload(workspace, [:repository])

    {:ok, integration} =
      Integrations.get_by(organization_id: workspace.organization_id, provider: :github)

    env = build_env_vars(workspace, integration)

    if is_nil(workspace.agent_id) or Application.get_env(:devhub, :agent) do
      do_unlock_terraform_state(workspace, env, lock_id)
    else
      DevhubWeb.AgentConnection.send_command(
        workspace.agent_id,
        {__MODULE__, :do_unlock_terraform_state, [workspace, env, lock_id]}
      )
    end
  end

  def do_unlock_terraform_state(workspace, env, lock_id) do
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    with :ok <- Client.create_or_update_secret(secret_name, env),
         {:ok, job_name} <- create_k8s_job(workspace, lock_id),
         {:ok, %{"metadata" => %{"name" => pod}}} <- Client.find_pod_for_job(job_name),
         {:ok, _log} <- stream_log(workspace.id, pod, "git"),
         {:ok, _log} <- stream_log(workspace.id, pod, "init"),
         {:ok, _log} <- stream_log(workspace.id, pod, "unlock") do
      {:ok, phase} = Client.get_finished_job_status(pod)

      cond do
        phase == "Succeeded" -> :ok
        phase == "Failed" -> :error
      end
    else
      error ->
        Logger.error("Failed to unlock terraform state: #{inspect(error)}")
        :error
    end
  end

  defp create_k8s_job(workspace, lock_id) do
    job_name = "unlock-#{lock_id}" |> String.replace("_", "-") |> String.downcase()
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    job_spec =
      job_spec(job_name, workspace, workspace.repository.default_branch,
        containers: [
          container(
            %{
              "name" => "unlock",
              "image" => workspace.docker_image,
              "args" => ["force-unlock", "--force", lock_id],
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
