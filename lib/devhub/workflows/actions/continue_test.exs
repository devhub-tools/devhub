defmodule Devhub.Workflows.Actions.ContinueTest do
  use Devhub.DataCase, async: true

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

  test "runs all actions" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    insert(:integration,
      organization: organization,
      provider: :slack,
      access_token: Jason.encode!(%{bot_token: "xoxb-1234567890"})
    )

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 1,
            condition: "true",
            action: %QueryAction{query: "SELECT id, name FROM users", credential_id: credential.id}
          ),
          # can support multiple queries
          build(:workflow_step,
            order: 2,
            action: %QueryAction{
              query: "SELECT id, name FROM users; SELECT id, name FROM users",
              credential_id: credential.id
            }
          ),
          build(:workflow_step,
            order: 3,
            action: %ConditionAction{condition: "true", when_false: :failed}
          ),
          build(:workflow_step,
            order: 4,
            condition: "false",
            name: "skip",
            action: %SlackAction{slack_channel: "#skip", message: "skipped"}
          ),
          build(:workflow_step,
            order: 5,
            name: "slack",
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          ),
          build(:workflow_step,
            order: 6,
            action: %SlackReplyAction{message: "this is a reply", reply_to_step_name: "slack"}
          ),
          build(:workflow_step,
            order: 7,
            action: %ApiAction{
              endpoint: "http://localhost:4002/_health",
              headers: [%ApiAction.Header{key: "x-api-key", value: "dh_123"}],
              body: ~s({"user_id": "${user_id}"}),
              include_devhub_jwt: true
            }
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    timestamp = "1742523346.254479"
    reply_timestamp = "1742523346.354479"

    Slack
    |> expect(:post_message, fn _organization_id, "#reviews", %{blocks: blocks} ->
      assert blocks == [
               %{type: "section", text: %{type: "mrkdwn", text: "Please review this"}},
               %{
                 type: "section",
                 text: %{
                   type: "mrkdwn",
                   text: "<#{DevhubWeb.Endpoint.url()}/workflows/#{run.workflow_id}/runs/#{run.id}|Review>"
                 }
               }
             ]

      {:ok, %{channel: "C05PBBGFFMM", timestamp: timestamp}}
    end)
    |> expect(:post_message, fn _organization_id, "C05PBBGFFMM", ^timestamp, %{blocks: blocks} ->
      assert blocks == [%{type: "section", text: %{type: "mrkdwn", text: "this is a reply"}}]

      {:ok, %{channel: "C05PBBGFFMM", timestamp: reply_timestamp}}
    end)

    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url: "http://localhost:4002/_health",
                              headers: [{"x-devhub-jwt", _jwt}, {"x-api-key", "dh_123"}]
                            },
                            _opts ->
      TeslaHelper.response(body: Jason.encode!(%{"user" => %{"name" => "michael"}}))
    end)

    assert {:ok,
            %Run{
              status: :completed,
              steps: [
                %Run.Step{
                  condition: "true",
                  status: :succeeded,
                  action: %QueryAction{},
                  output: %{
                    "columns" => ["id", "name"],
                    "command" => :select,
                    "messages" => [],
                    "num_rows" => 0,
                    "rows" => []
                  }
                },
                %Run.Step{
                  status: :succeeded,
                  action: %QueryAction{},
                  output: %{results: ["select 0", "select 0"]}
                },
                %Run.Step{
                  output: %{"eval" => true},
                  status: :succeeded,
                  action: %ConditionAction{}
                },
                %Run.Step{
                  condition: "false",
                  status: :skipped,
                  action: %SlackAction{},
                  output: nil
                },
                %Run.Step{
                  status: :succeeded,
                  action: %SlackAction{},
                  output: %{"channel" => "C05PBBGFFMM", "timestamp" => ^timestamp}
                },
                %Run.Step{
                  status: :succeeded,
                  action: %SlackReplyAction{},
                  output: %{"channel" => "C05PBBGFFMM", "timestamp" => ^reply_timestamp}
                },
                %Run.Step{
                  status: :succeeded,
                  action: %ApiAction{},
                  output: %{
                    "status_code" => 200,
                    "body" => %{"user" => %{"name" => "michael"}}
                  }
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "stops on query failure status" do
    organization = insert(:organization)
    credential = insert(:database_credential, database: build(:database, organization: organization))

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 1,
            action: %QueryAction{query: "SELECT * FROM users", credential_id: credential.id}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    expect(Devhub.QueryDesk, :run_query, fn _query ->
      {:error, "Database connection error"}
    end)

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                %Run.Step{
                  status: :failed,
                  action: %QueryAction{},
                  output: %{"error" => "Database connection error"}
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "stops on slack failure" do
    organization = insert(:organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 1,
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    expect(Slack, :post_message, fn _organization_id, "#reviews", _message ->
      {:error, :failed_to_post_message}
    end)

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                %Run.Step{
                  status: :failed,
                  action: %SlackAction{},
                  output: %{"error" => :failed_to_post_message}
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "stops on api failure" do
    organization = insert(:organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 0,
            action: %ApiAction{
              endpoint: "http://localhost:4002/_health"
            }
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    # unexpected status code
    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url: "http://localhost:4002/_health"
                            },
                            _opts ->
      TeslaHelper.response(status: 400, body: "invalid input")
    end)

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                %Run.Step{
                  status: :failed,
                  action: %ApiAction{},
                  output: %{"status_code" => 400, "body" => "invalid input"}
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})

    # timeout
    {:ok, run} = Workflows.run_workflow(workflow, %{})

    expect(Finch, :call, fn %Tesla.Env{
                              method: :get,
                              url: "http://localhost:4002/_health"
                            },
                            _opts ->
      {:error, :timeout}
    end)

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                %Run.Step{
                  status: :failed,
                  action: %ApiAction{},
                  output: %{"error" => :timeout}
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "stops on condition not met" do
    organization = insert(:organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step, order: 1, action: %ConditionAction{condition: "false", when_false: :failed}),
          build(:workflow_step,
            order: 2,
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                # the step succeeds because it did process, and it marked the run as failed
                %Run.Step{
                  status: :succeeded,
                  action: %ConditionAction{},
                  output: %{"eval" => false}
                },
                %Run.Step{status: :pending, action: %SlackAction{}}
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "step condition handles invalid condition" do
    organization = insert(:organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 1,
            condition: "(",
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          ),
          build(:workflow_step,
            order: 2,
            action: %ConditionAction{condition: "true", when_false: :failed}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                %Run.Step{status: :failed, action: %SlackAction{}},
                %Run.Step{
                  status: :pending,
                  action: %ConditionAction{},
                  output: nil
                }
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end

  test "condition action handles invalid condition" do
    organization = insert(:organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step, order: 1, action: %ConditionAction{condition: "(", when_false: :failed}),
          build(:workflow_step,
            order: 2,
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, run} = Workflows.run_workflow(workflow, %{})

    assert {:ok,
            %Run{
              status: :failed,
              steps: [
                # the step succeeds because it did process, and it marked the run as failed
                %Run.Step{
                  status: :failed,
                  action: %ConditionAction{},
                  output: %{"eval" => "error"}
                },
                %Run.Step{status: :pending, action: %SlackAction{}}
              ]
            }} = perform_job(RunWorkflow, %{id: run.id})
  end
end
