defmodule Devhub.TerraDesk.Actions.UnlockTerraformStateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk

  test "unlocks state" do
    organization = insert(:organization)

    workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization))
      |> Devhub.Repo.preload([:organization, :env_vars, :secrets, :workload_identity])

    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn name, env ->
      assert name == workspace.id |> String.replace("_", "-") |> String.downcase()

      assert [{"GITHUB_TOKEN", _github_token}] = env

      :ok
    end)
    |> expect(:create_job, fn spec ->
      assert %{
               "metadata" => %{"name" => "unlock-lock-id"},
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "initContainers" => [
                       %{"name" => "git", "securityContext" => _init_security_context},
                       %{"name" => "init", "securityContext" => _git_security_context}
                     ],
                     "containers" => [%{"name" => "unlock", "securityContext" => _unlock_security_context}]
                   }
                 }
               }
             } = spec

      :ok
    end)
    |> expect(:find_pod_for_job, fn "unlock-lock-id" ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      TeslaHelper.response(body: ["git log"])
    end)
    |> expect(:get_log, fn "pod-name", "init" ->
      TeslaHelper.response(body: ["init log"])
    end)
    |> expect(:get_log, fn "pod-name", "unlock" ->
      TeslaHelper.response(body: ["unlock log"])
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert :ok = TerraDesk.unlock_terraform_state(workspace, "lock-id")
  end

  test "handles failure" do
    organization = insert(:organization)

    workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization))
      |> Devhub.Repo.preload([:organization, :env_vars, :secrets, :workload_identity])

    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn _name, _env ->
      :ok
    end)
    |> expect(:create_job, fn _spec ->
      :ok
    end)
    |> expect(:find_pod_for_job, fn "unlock-lock-id" ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      {:error, :failed_to_get_log}
    end)

    assert :error = TerraDesk.unlock_terraform_state(workspace, "lock-id")
  end
end
