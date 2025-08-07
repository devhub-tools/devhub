defmodule Devhub.TerraDesk.Utils.BuildEnvVars do
  @moduledoc false

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.Google
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.TerraDesk.Schemas.Workspace

  require Logger

  @spec build_env_vars(workspace :: Workspace.t(), Integration.t()) :: [{String.t(), String.t()}]
  def build_env_vars(workspace, github) do
    token = Client.get_token(github)

    secrets =
      Enum.map(workspace.secrets, fn secret ->
        {"TF_VAR_" <> secret.name, secret.value}
      end)

    env_vars =
      Enum.map(workspace.env_vars, fn env_var ->
        {env_var.name, env_var.value}
      end)

    maybe_add_google_access_token(
      [{"GITHUB_TOKEN", token} | secrets ++ env_vars],
      workspace
    )
  end

  defp maybe_add_google_access_token(env, %{workload_identity: %{enabled: true}} = workspace) do
    case Google.access_token(workspace.workload_identity) do
      {:ok, token} -> [{"GOOGLE_OAUTH_ACCESS_TOKEN", token} | env]
      _error -> env
    end
  end

  defp maybe_add_google_access_token(env, _workspace) do
    env
  end
end
