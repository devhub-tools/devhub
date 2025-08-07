defmodule Devhub.TerraDesk.Actions.RunPlanTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Kubernetes
  alias Devhub.TerraDesk
  alias Devhub.TerraDesk.Schemas.Plan

  test "runs plan" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    plan = insert(:plan, workspace: workspace, organization: organization, targeted_resources: ["resource.type"])
    insert(:integration, organization: organization, provider: :github)
    job_name = "plan-#{plan.id}-1" |> String.replace("_", "-") |> String.downcase()

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    Kubernetes.Client
    |> expect(:create_or_update_secret, fn _name, env ->
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
                       %{"name" => "plan", "securityContext" => _plan_security_context}
                     ],
                     "containers" => [%{"name" => "upload-plan", "securityContext" => _upload_security_context}]
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
    |> expect(:get_log, fn "pod-name", "plan" ->
      TeslaHelper.response(body: ["plan log"])
    end)
    |> expect(:get_finished_job_status, fn "pod-name" ->
      {:ok, "Succeeded"}
    end)

    assert {:ok, %Plan{status: :planned, log: "git log\ninit log\nplan log"}} =
             TerraDesk.run_plan(plan)
  end

  test "notifies slack after scheduled plan" do
    organization = insert(:organization)
    agent = insert(:agent, organization: organization)
    schedule = insert(:terradesk_schedule, organization: organization)

    insert(:integration,
      organization: organization,
      provider: :slack,
      access_token: Jason.encode!(%{bot_token: "xoxb-1234567890"})
    )

    workspace =
      insert(:workspace,
        organization: organization,
        repository: build(:repository, organization: organization),
        agent: agent,
        schedules: [schedule]
      )

    plan = insert(:plan, workspace: workspace, organization: organization, schedule: schedule)
    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    expect(DevhubWeb.AgentConnection, :send_command, fn _agent_id, _fun ->
      {:ok, %{status: :planned, log: "2 to add, 1 to change, 1 to destroy"}}
    end)

    expect(Tesla.Adapter.Finch, :call, fn %Tesla.Env{
                                            method: :post,
                                            url: "https://slack.com/api/chat.postMessage",
                                            body: body
                                          },
                                          _opts ->
      assert {
               :ok,
               %{
                 "channel" => "#alerts",
                 "thread_ts" => nil,
                 "attachments" => [],
                 "blocks" => [
                   %{
                     "text" => %{
                       "text" => "Drift detection run for `server-config` finished: 2 to add, 1 to change, 1 to destroy",
                       "type" => "mrkdwn"
                     },
                     "type" => "section"
                   },
                   %{
                     "text" => %{
                       "text" => "<http://localhost:4002/terradesk/plans/#{plan.id}|Review plan>",
                       "type" => "mrkdwn"
                     },
                     "type" => "section"
                   }
                 ]
               }
             } == Jason.decode(body)

      TeslaHelper.response(body: %{"ts" => "1234567890.123456", "channel" => "C12345678"})
    end)

    assert {:ok, %Plan{status: :planned}} =
             TerraDesk.run_plan(plan)
  end

  test "handles failure" do
    organization = insert(:organization)
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))
    plan = insert(:plan, workspace: workspace, organization: organization)
    insert(:integration, organization: organization, provider: :github)
    job_name = "plan-#{plan.id}-1" |> String.replace("_", "-") |> String.downcase()

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

    assert {:ok, %Plan{status: :failed}} = TerraDesk.run_plan(plan)
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

    plan = insert(:plan, workspace: workspace, organization: organization)
    insert(:integration, organization: organization, provider: :github)

    expect(GitHub.Client, :get_token, fn _integration -> Ecto.UUID.generate() end)

    assert {:ok, %Plan{status: :failed}} = TerraDesk.run_plan(plan)
  end
end
