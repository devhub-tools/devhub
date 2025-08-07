defmodule DevhubWeb.Live.Workflows.RunTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.Slack
  alias Devhub.Workflows
  alias Devhub.Workflows.Jobs.RunWorkflow
  alias Devhub.Workflows.Schemas.Run
  alias Devhub.Workflows.Schemas.Step.ApiAction
  alias Devhub.Workflows.Schemas.Step.ConditionAction
  alias Devhub.Workflows.Schemas.Step.QueryAction
  alias Devhub.Workflows.Schemas.Step.SlackAction
  alias Devhub.Workflows.Schemas.Step.SlackReplyAction
  alias Tesla.Adapter.Finch

  test "can view run", %{conn: conn, user: %{id: user_id}, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}, %{key: "ticket_url", type: :string}],
        steps: [
          build(:workflow_step,
            name: "condition",
            order: 1,
            condition: "true",
            action: %ConditionAction{condition: "true", when_false: :failed}
          ),
          build(:workflow_step,
            name: "query",
            order: 2,
            condition: "true",
            action: %QueryAction{query: "SELECT * FROM users", credential_id: credential.id}
          ),
          build(:workflow_step,
            name: "slack",
            order: 2,
            condition: "true",
            name: "request-review",
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          ),
          build(:workflow_step,
            name: "api",
            order: 3,
            condition: "true",
            action: %ApiAction{
              endpoint: "http://localhost:4002/_health",
              headers: [%ApiAction.Header{key: "x-api-key", value: "dh_123"}]
            }
          ),
          build(:workflow_step,
            name: "slack-reply",
            order: 4,
            condition: "true",
            name: "reply-finished",
            action: %SlackReplyAction{message: "Workflow complete", reply_to_step_name: "request-review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} =
      Workflows.run_workflow(workflow, %{
        "user_id" => user_id,
        "ticket_url" => "https://linear.app",
        "triggered_by_user_id" => user_id
      })

    timestamp = "1742523346.254479"

    expect(Slack, :post_message, fn _organization_id, "#reviews", _message ->
      {:ok, %{channel: "C05PBBGFFMM", timestamp: timestamp}}
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url: "http://localhost:4002/_health",
                              headers: [{"x-api-key", "dh_123"}]
                            },
                            _opts ->
      TeslaHelper.response(body: "ok")
    end)

    expect(Slack, :post_message, fn _organization_id, "C05PBBGFFMM", ^timestamp, _message ->
      {:ok, %{channel: "C05PBBGFFMM", timestamp: "#{DateTime.to_unix(DateTime.utc_now())}.1"}}
    end)

    assert {:ok, %Run{status: :completed}} = perform_job(RunWorkflow, %{id: run.id})

    {:ok, run} = Workflows.get_run(id: run.id)

    Registry.dispatch(LiveSync.Registry, "live_sync:#{organization.id}", fn subscribed ->
      for {pid, _opts} <- subscribed, do: send(pid, {:live_sync, [{:update, run}]})
    end)

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}/runs/#{run.id}")

    assert render(view) =~ "Completed"
  end

  test "replaces variables in body", %{conn: conn, user: %{id: user_id}, organization: organization} do
    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}],
        steps: [
          build(:workflow_step,
            order: 0,
            action: %ApiAction{
              endpoint: "http://localhost:4002/_health",
              headers: [%ApiAction.Header{key: "x-api-key", value: "dh_123"}],
              body: ~s({"user_id": "${user_id}"})
            }
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} =
      Workflows.run_workflow(workflow, %{
        "user_id" => user_id,
        "triggered_by_user_id" => user_id
      })

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}/runs/#{run.id}")

    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url: "http://localhost:4002/_health",
                              headers: [{"x-api-key", "dh_123"}]
                            },
                            _opts ->
      TeslaHelper.response(body: "ok")
    end)

    assert {:ok, %Run{status: :completed}} = perform_job(RunWorkflow, %{id: run.id})

    {:ok, run} = Workflows.get_run(id: run.id)

    Registry.dispatch(LiveSync.Registry, "live_sync:#{organization.id}", fn subscribed ->
      for {pid, _opts} <- subscribed, do: send(pid, {:live_sync, [{:update, run}]})
    end)

    assert render(view) =~ ~s({&quot;user_id&quot;: &quot;#{user_id}&quot;})
  end

  test "displays triggered by linear issue", %{conn: conn, organization: organization} do
    linear_issue = insert(:linear_issue, organization: organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        steps: [
          build(:workflow_step,
            name: "condition",
            order: 1,
            condition: "true",
            action: %ConditionAction{condition: "true", when_false: :failed}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{"triggered_by_linear_issue_id" => linear_issue.id})
    {:ok, _view, html} = live(conn, ~p"/workflows/#{workflow.id}/runs/#{run.id}")

    assert html =~ linear_issue.identifier
  end
end
