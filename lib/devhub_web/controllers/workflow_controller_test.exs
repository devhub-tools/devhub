defmodule DevhubWeb.V1.WorkflowControllerTest do
  use DevhubWeb.ConnCase, async: true

  alias Devhub.Workflows.Schemas.Step.ApiAction
  alias Devhub.Workflows.Schemas.Step.ConditionAction
  alias Devhub.Workflows.Schemas.Step.QueryAction
  alias Devhub.Workflows.Schemas.Step.SlackAction
  alias Devhub.Workflows.Schemas.Step.SlackReplyAction

  setup %{organization: organization} do
    stub(Devhub.ApiKeys, :verify, fn _id -> {:ok, build(:api_key, organization: organization)} end)
    :ok
  end

  @tag :unauthenticated
  test "POST /api/v1/workflows/:id/run", %{conn: conn, organization: organization} do
    workflow = insert(:workflow, organization: organization, inputs: [%{key: "user_id", type: :string}])

    conn
    |> put_req_header("x-api-key", "dh_123")
    |> post(~p"/api/v1/workflows/#{workflow.id}/run", %{user_id: "123"})
    |> text_response(201)

    assert_enqueued worker: Devhub.Workflows.Jobs.RunWorkflow

    conn
    |> put_req_header("x-api-key", "dh_123")
    |> post(~p"/api/v1/workflows/#{workflow.id}/run", %{})
    |> text_response(400)

    conn
    |> put_req_header("x-api-key", "dh_123")
    |> post(~p"/api/v1/workflows/not-found/run", %{})
    |> text_response(404)
  end

  @tag :unauthenticated
  test "GET /api/v1/workflows/:id", %{conn: conn, organization: organization} do
    %{id: credential_id} = insert(:database_credential, database: build(:database, organization: organization))
    %{id: linear_label_id, name: linear_label_name} = insert(:linear_label, organization: organization)

    %{id: workflow_id, name: workflow_name} =
      :workflow
      |> build(
        organization: organization,
        trigger_linear_label_id: linear_label_id,
        inputs: [%{key: "user_id", type: :string, description: "User ID"}],
        steps: [
          build(:workflow_step,
            order: 1,
            action: %ConditionAction{condition: "true", when_false: :failed}
          ),
          build(:workflow_step,
            order: 2,
            action: %QueryAction{query: "SELECT * FROM users", credential_id: credential_id}
          ),
          build(:workflow_step,
            order: 3,
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          ),
          build(:workflow_step,
            order: 4,
            action: %ApiAction{
              endpoint: "http://localhost:4002/_health",
              headers: [%ApiAction.Header{key: "x-api-key", value: "dh_123"}]
            }
          ),
          build(:workflow_step,
            order: 5,
            action: %SlackReplyAction{message: "this is a reply"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    assert %{
             "id" => ^workflow_id,
             "inputs" => [
               %{"description" => "User ID", "key" => "user_id", "type" => "string"}
             ],
             "trigger_linear_label" => %{
               "id" => ^linear_label_id,
               "name" => ^linear_label_name
             },
             "name" => ^workflow_name,
             "steps" => [
               %{
                 "action" => %{"condition" => "true", "when_false" => "failed", "__type__" => "condition"},
                 "name" => nil,
                 "order" => 1
               },
               %{
                 "action" => %{
                   "credential_id" => ^credential_id,
                   "query" => "SELECT * FROM users",
                   "timeout" => 5,
                   "__type__" => "query"
                 },
                 "name" => nil,
                 "order" => 2
               },
               %{
                 "action" => %{
                   "link_text" => "Review",
                   "message" => "Please review this",
                   "slack_channel" => "#reviews",
                   "__type__" => "slack"
                 },
                 "name" => nil,
                 "order" => 3
               },
               %{
                 "action" => %{
                   "body" => nil,
                   "endpoint" => "http://localhost:4002/_health",
                   "expected_status_code" => 200,
                   "headers" => [%{"key" => "x-api-key", "value" => "dh_123"}],
                   "include_devhub_jwt" => false,
                   "method" => "GET",
                   "__type__" => "api"
                 },
                 "name" => nil,
                 "order" => 4
               },
               %{
                 "action" => %{
                   "message" => "this is a reply",
                   "reply_to_step_name" => nil,
                   "__type__" => "slack_reply"
                 },
                 "name" => nil,
                 "order" => 5
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> get(~p"/api/v1/workflows/#{workflow_id}")
             |> json_response(200)
  end

  @tag :unauthenticated
  test "POST /api/v1/workflows", %{conn: conn, organization: organization} do
    %{id: linear_label_id, name: linear_label_name} = insert(:linear_label, organization: organization)

    input = %{
      "name" => "My workflow",
      "trigger_linear_label" => %{
        "name" => linear_label_name
      },
      "inputs" => [
        %{"description" => "User ID", "key" => "user_id", "type" => "string"}
      ],
      "steps" => [
        %{
          "action" => %{
            "link_text" => "Review",
            "message" => "Please review this",
            "slack_channel" => "#reviews",
            "__type__" => "slack"
          },
          "name" => nil,
          "order" => 0
        }
      ]
    }

    assert %{
             "name" => "My workflow",
             "trigger_linear_label" => %{
               "id" => ^linear_label_id,
               "name" => ^linear_label_name
             },
             "inputs" => [
               %{"description" => "User ID", "key" => "user_id", "type" => "string"}
             ],
             "steps" => [
               %{
                 "action" => %{
                   "link_text" => "Review",
                   "message" => "Please review this",
                   "slack_channel" => "#reviews",
                   "__type__" => "slack"
                 },
                 "name" => nil,
                 "order" => 0
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> post(~p"/api/v1/workflows", input)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "PATCH /api/v1/workflows/:id", %{conn: conn, organization: organization} do
    %{id: credential_id} = insert(:database_credential, database: build(:database, organization: organization))

    %{id: workflow_id, steps: [%{id: step_id_1}, %{id: step_id_2}]} =
      :workflow
      |> build(
        organization: organization,
        steps: [
          build(:workflow_step,
            order: 1,
            name: "query",
            action: %QueryAction{query: "SELECT id, name FROM users", credential_id: credential_id}
          ),
          build(:workflow_step,
            order: 2,
            name: "slack",
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    input = %{
      "inputs" => [
        %{"description" => "User ID", "key" => "user_id", "type" => "string"}
      ],
      "name" => "My workflow",
      "steps" => [
        %{
          "id" => step_id_1,
          "action" => %{
            "message" => "Please review this",
            "link_text" => "Review",
            "slack_channel" => "#reviews",
            "__type__" => "slack"
          },
          "name" => "slack",
          "order" => 0
        },
        %{
          "id" => step_id_2,
          "action" => %{
            "credential_id" => credential_id,
            "query" => "SELECT id, name FROM users",
            "timeout" => 5,
            "__type__" => "query"
          },
          "name" => "query",
          "order" => 1
        }
      ]
    }

    assert %{
             "id" => ^workflow_id,
             "name" => "My workflow",
             "inputs" => [
               %{"description" => "User ID", "key" => "user_id", "type" => "string"}
             ],
             "steps" => [
               %{
                 "action" => %{
                   "message" => "Please review this",
                   "link_text" => "Review",
                   "slack_channel" => "#reviews",
                   "__type__" => "slack"
                 },
                 "name" => "slack",
                 "order" => 0
               },
               %{
                 "action" => %{
                   "credential_id" => ^credential_id,
                   "query" => "SELECT id, name FROM users",
                   "timeout" => 5,
                   "__type__" => "query"
                 },
                 "name" => "query",
                 "order" => 1
               }
             ]
           } =
             conn
             |> put_req_header("x-api-key", "dh_123")
             |> patch(~p"/api/v1/workflows/#{workflow_id}", input)
             |> json_response(200)
  end

  @tag :unauthenticated
  test "DELETE /api/v1/workflows/:id", %{conn: conn, organization: organization} do
    %{id: workflow_id} = insert(:workflow, organization: organization)

    conn
    |> put_req_header("x-api-key", "dh_123")
    |> delete(~p"/api/v1/workflows/#{workflow_id}")
    |> json_response(200)

    refute Devhub.Repo.get(Devhub.Workflows.Schemas.Workflow, workflow_id)
  end
end
