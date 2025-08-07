defmodule Devhub.TerraDesk.Actions.MoveTerraformStateTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk

  test "move state" do
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
               "metadata" => %{"name" => "move-" <> _name},
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "initContainers" => [
                       %{"name" => "git", "securityContext" => _init_security_context},
                       %{"name" => "init", "securityContext" => _git_security_context}
                     ],
                     "containers" => [%{"name" => "move", "securityContext" => _move_security_context}]
                   }
                 }
               }
             } = spec

      :ok
    end)
    |> expect(:find_pod_for_job, fn "move-" <> _name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      TeslaHelper.response(body: ["git log"])
    end)
    |> expect(:get_log, fn "pod-name", "init" ->
      TeslaHelper.response(body: ["init log"])
    end)
    |> expect(:get_log, fn "pod-name", "move" ->
      TeslaHelper.response(body: ["move log"])
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert :ok = TerraDesk.move_terraform_state(workspace, "module.example[0].foo", "module.example[1].bar")
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
    |> expect(:find_pod_for_job, fn "move-" <> _name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      {:error, :failed_to_get_log}
    end)

    assert :error = TerraDesk.move_terraform_state(workspace, "from", "to")
  end
end
