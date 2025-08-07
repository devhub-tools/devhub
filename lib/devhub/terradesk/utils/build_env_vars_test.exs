defmodule Devhub.TerraDesk.Utils.BuildEnvVarsTest do
  use Devhub.DataCase, async: true

  import Devhub.TerraDesk.Utils.BuildEnvVars

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Google

  test "builds env vars" do
    organization = insert(:organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        workload_identity: %{enabled: true, organization: organization},
        env_vars: [build(:terradesk_env_var, name: "ENV_VAR_NAME", value: "ENV_VAR_VALUE")],
        secrets: [build(:terradesk_secret, name: "API_KEY", value: "api-key")]
      )

    expect(GitHub.Client, :get_token, fn _integration -> "github-token" end)
    integration = insert(:integration, organization: organization, provider: :github)

    expect(Google, :access_token, fn _workload_identity -> {:ok, "google-token"} end)

    assert [
             {"GOOGLE_OAUTH_ACCESS_TOKEN", "google-token"},
             {"GITHUB_TOKEN", "github-token"},
             {"TF_VAR_API_KEY", "api-key"},
             {"ENV_VAR_NAME", "ENV_VAR_VALUE"}
           ] = build_env_vars(workspace, integration)
  end
end
