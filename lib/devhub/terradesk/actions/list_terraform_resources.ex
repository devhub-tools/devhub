defmodule Devhub.TerraDesk.Actions.ListTerraformResources do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.TerraDesk.Utils.BuildEnvVars
  import Devhub.TerraDesk.Utils.Container
  import Devhub.TerraDesk.Utils.JobSpec

  alias Devhub.Integrations
  alias Devhub.Integrations.Kubernetes.Client
  alias Devhub.TerraDesk.Schemas.Workspace
  alias Devhub.TerraDesk.TerraformStateCache

  require Logger

  @callback list_terraform_resources(Workspace.t()) :: [String.t()]
  @callback list_terraform_resources(Workspace.t(), Keyword.t()) :: [String.t()]
  def list_terraform_resources(workspace, opts \\ []) do
    workspace = Devhub.Repo.preload(workspace, [:repository])

    with false <- Keyword.get(opts, :refresh, false),
         resources when is_list(resources) <- TerraformStateCache.get_resources(workspace) do
      resources
    else
      _refresh ->
        {:ok, integration} =
          Integrations.get_by(organization_id: workspace.organization_id, provider: :github)

        env = build_env_vars(workspace, integration)

        result =
          if is_nil(workspace.agent_id) or Application.get_env(:devhub, :agent) do
            do_fetch_resources(workspace, env)
          else
            DevhubWeb.AgentConnection.send_command(
              workspace.agent_id,
              {__MODULE__, :do_fetch_resources, [workspace, env]}
            )
          end

        case result do
          {:ok, resources} ->
            :ok = TerraformStateCache.update_resources(workspace, resources)
            resources

          {:error, error} ->
            Logger.error("Failed to list state: #{inspect(error)}")
            []
        end
    end
  end

  def do_fetch_resources(workspace, env) do
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    :ok = Client.create_or_update_secret(secret_name, env)

    with {:ok, job_name} <- create_k8s_job(workspace),
         {:ok, %{"metadata" => %{"name" => pod}}} <- Client.find_pod_for_job(job_name),
         {:ok, _git_log} <- Client.get_log(pod, "git"),
         {:ok, _init_log} <- Client.get_log(pod, "init"),
         {:ok, %{body: body}} <- Client.get_log(pod, "state-list") do
      output = Enum.join(body, "")

      {:ok, phase} = Client.get_finished_job_status(pod)

      cond do
        phase == "Succeeded" ->
          resources = String.split(output, "\n", trim: true)
          {:ok, resources}

        phase == "Failed" ->
          {:error, output}
      end
    else
      error -> {:error, error}
    end
  end

  defp create_k8s_job(workspace) do
    job_name = "state-list-#{Ecto.UUID.generate()}" |> String.replace("_", "-") |> String.downcase()
    secret_name = workspace.id |> String.replace("_", "-") |> String.downcase()

    job_spec =
      job_spec(job_name, workspace, workspace.repository.default_branch,
        containers: [
          container(
            %{
              "name" => "state-list",
              "image" => workspace.docker_image,
              "args" => ["state", "list"],
              "workingDir" => "/workspace/#{workspace.path}"
            },
            secret_name
          )
        ]
      )

    :ok = Client.create_job(job_spec)
    {:ok, job_name}
  end
end
