defmodule Devhub.TerraDesk.Actions.ListTerraformResourcesTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.TerraformStateCache

  test "cache is empty" do
    organization = insert(:organization)

    workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization))
      |> Devhub.Repo.preload([:organization, :env_vars, :secrets, :workload_identity])

    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn _name, env ->
      assert [{"GITHUB_TOKEN", _github_token}] = env

      :ok
    end)
    |> expect(:create_job, fn spec ->
      assert %{
               "metadata" => %{"name" => job_name},
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "initContainers" => [
                       %{"name" => "git", "securityContext" => _init_security_context},
                       %{"name" => "init", "securityContext" => _git_security_context}
                     ],
                     "containers" => [%{"name" => "state-list", "securityContext" => _list_security_context}]
                   }
                 }
               }
             } = spec

      assert "state-list-" <> _job_uuid = job_name
      :ok
    end)
    |> expect(:find_pod_for_job, fn job_name ->
      assert "state-list-" <> _job_uuid = job_name
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      TeslaHelper.response(body: ["git log"])
    end)
    |> expect(:get_log, fn "pod-name", "init" ->
      TeslaHelper.response(body: ["init log"])
    end)
    |> expect(:get_log, fn "pod-name", "state-list" ->
      TeslaHelper.response(
        body: [
          """
          module.foo.null_resource.bar
          module.foo.null_resource.baz
          """
        ]
      )
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert ["module.foo.null_resource.bar", "module.foo.null_resource.baz"] =
             TerraDesk.list_terraform_resources(workspace)
  end

  test "cache is populated" do
    organization = insert(:organization)

    workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization))
      |> Devhub.Repo.preload([:organization, :env_vars, :secrets, :workload_identity])

    # make cache return results
    expect(TerraformStateCache, :get_resources, fn ^workspace ->
      ["module.foo.null_resource.bar", "module.foo.null_resource.baz"]
    end)

    assert ["module.foo.null_resource.bar", "module.foo.null_resource.baz"] =
             TerraDesk.list_terraform_resources(workspace)
  end

  test "refresh triggers refetch" do
    organization = insert(:organization)

    workspace =
      :workspace
      |> insert(organization: organization, repository: build(:repository, organization: organization))
      |> Devhub.Repo.preload([:organization, :env_vars, :secrets, :workload_identity])

    insert(:integration, organization: organization, provider: :github)

    # because refresh was passed, we expect the cache to be bypassed
    reject(&TerraformStateCache.get_resources/1)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn _name, _env ->
      :ok
    end)
    |> expect(:create_job, fn _spec ->
      :ok
    end)
    |> expect(:find_pod_for_job, fn _job_name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      TeslaHelper.response(body: ["git log"])
    end)
    |> expect(:get_log, fn "pod-name", "init" ->
      TeslaHelper.response(body: ["init log"])
    end)
    |> expect(:get_log, fn "pod-name", "state-list" ->
      TeslaHelper.response(
        body: [
          """
          module.foo.null_resource.bar
          module.foo.null_resource.baz
          """
        ]
      )
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert ["module.foo.null_resource.bar", "module.foo.null_resource.baz"] =
             TerraDesk.list_terraform_resources(workspace, refresh: true)
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
    |> expect(:find_pod_for_job, fn _job_name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      {:error, :failed_to_get_log}
    end)

    assert [] = TerraDesk.list_terraform_resources(workspace)
  end
end
