defmodule Devhub.TerraDesk.Actions.RunApplyTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "runs plan" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    insert(:integration, organization: organization, provider: :github)

    plan =
      insert(:plan,
        workspace: workspace,
        organization: organization,
        status: :planned,
        log: "plan complete",
        output: <<0>>
      )

    job_name = "apply-#{plan.id}" |> String.replace("_", "-") |> String.downcase()

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn name, env ->
      assert name == plan.workspace.id |> String.replace("_", "-") |> String.downcase()

      assert [
               {"INTERNAL_TOKEN", _internal_token},
               {"GITHUB_TOKEN", _github_token}
             ] = env

      :ok
    end)
    |> expect(:create_job, fn spec ->
      assert %{
               "metadata" => %{"name" => ^job_name},
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "initContainers" => [
                       %{"name" => "git", "securityContext" => _init_security_context},
                       %{"name" => "init", "securityContext" => _git_security_context},
                       %{"name" => "download-plan", "securityContext" => _download_security_context}
                     ],
                     "containers" => [
                       %{"name" => "apply", "securityContext" => _apply_security_context}
                     ]
                   }
                 }
               }
             } = spec

      :ok
    end)
    |> expect(:find_pod_for_job, fn ^job_name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      TeslaHelper.response(body: ["git log"])
    end)
    |> expect(:get_log, fn "pod-name", "init" ->
      TeslaHelper.response(body: ["init log"])
    end)
    |> expect(:get_log, fn "pod-name", "apply" ->
      TeslaHelper.response(body: ["apply log"])
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert {:ok, %Plan{status: :applied, log: "plan complete\napply log", output: nil}} =
             TerraDesk.run_apply(plan)
  end

  test "handles failure" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    plan = insert(:plan, workspace: workspace, organization: organization, status: :planned, log: "", output: <<0>>)
    insert(:integration, organization: organization, provider: :github)
    job_name = "apply-#{plan.id}" |> String.replace("_", "-") |> String.downcase()

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn _name, _env ->
      :ok
    end)
    |> expect(:create_job, fn _spec ->
      :ok
    end)
    |> expect(:find_pod_for_job, fn ^job_name ->
      {:ok, %{"metadata" => %{"name" => "pod-name"}}}
    end)
    |> expect(:get_log, fn "pod-name", "git" ->
      {:error, :failed_to_get_log}
    end)

    assert {:ok, %Plan{status: :failed}} = TerraDesk.run_apply(plan)
  end

  test "agent not online" do
    organization = insert(:organization)
    agent = insert(:agent, organization: organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        agent: agent
      )

    plan = insert(:plan, workspace: workspace, organization: organization, status: :planned)
    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    assert {:ok, %Plan{status: :failed}} = TerraDesk.run_apply(plan)
  end

  test "can't run without approvals" do
    organization = insert(:organization)

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        required_approvals: 1
      )

    plan = insert(:plan, workspace: workspace, organization: organization, status: :planned)

    assert_raise RuntimeError, fn -> TerraDesk.run_apply(plan) end
  end
end
