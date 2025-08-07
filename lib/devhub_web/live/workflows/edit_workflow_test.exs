defmodule DevhubWeb.Live.Workflows.EditWorkflowTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Workflows.Schemas.Step
  alias Devhub.Workflows.Schemas.Step.ConditionAction
  alias Devhub.Workflows.Schemas.Step.QueryAction
  alias Devhub.Workflows.Schemas.Step.SlackAction
  alias Devhub.Workflows.Schemas.Step.SlackReplyAction
  alias Devhub.Workflows.Schemas.Workflow

  test "can edit", %{conn: conn, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}],
        steps: [
          build(:workflow_step,
            order: 0,
            action: %ConditionAction{condition: "true", when_false: :failed}
          ),
          build(:workflow_step,
            order: 1,
            action: %QueryAction{query: "SELECT * FROM users", credential_id: credential.id}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}/edit")

    assert view
           |> element(~s(form[phx-change="update"]))
           |> render_change(%{
             _target: ["workflow", "name"],
             workflow: %{
               name: "New name",
               steps: %{
                 "0" => %{
                   action: %{condition: "false", when_false: "succeeded"}
                 },
                 "1" => %{
                   action: %{query: "SELECT * FROM organizations", credential_search: "other"}
                 }
               }
             }
           }) =~ "New name"

    assert %Workflow{
             steps: [
               %Step{
                 action: %ConditionAction{condition: "false", when_false: :succeeded}
               },
               %Step{
                 action: %QueryAction{query: "SELECT * FROM organizations"}
               }
             ]
           } = Workflow |> Devhub.Repo.get(workflow.id) |> Devhub.Repo.preload(:steps)
  end

  test "credential search", %{conn: conn, organization: organization} do
    credential = insert(:database_credential, database: build(:database, organization: organization))

    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}],
        steps: [
          build(:workflow_step,
            order: 1,
            action: %QueryAction{query: "SELECT * FROM users", credential_id: credential.id}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}/edit")

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["workflow", "steps", 0, "action", "credential_search"],
      workflow: %{
        steps: %{
          "0" => %{
            action: %{query: "SELECT * FROM users", credential_search: "other"}
          }
        }
      }
    })

    refute has_element?(view, ~s([data-testid="#{credential.id}-option"]))

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["workflow", "steps", 0, "action", "credential_search"],
      workflow: %{
        steps: %{
          "0" => %{
            action: %{query: "SELECT * FROM users", credential_search: credential.database.name}
          }
        }
      }
    })

    assert has_element?(view, ~s([data-testid="#{credential.id}-option"]))
  end

  test "label search", %{conn: conn, organization: organization} do
    label = insert(:linear_label, organization: organization)

    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}]
      )
      |> Devhub.Repo.insert!()

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}/edit")

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["workflow", "trigger_linear_label_search"],
      workflow: %{
        trigger_linear_label_search: label.name
      }
    })

    assert has_element?(view, ~s([data-testid="#{label.id}-option"]))

    view
    |> element(~s(form[phx-change="update"]))
    |> render_change(%{
      _target: ["workflow", "trigger_linear_label_search"],
      workflow: %{
        trigger_linear_label_search: "other"
      }
    })

    refute has_element?(view, ~s([data-testid="#{label.id}-option"]))
  end

  test "add step", %{conn: conn, organization: organization} do
    workflow =
      insert(:workflow,
        organization: organization,
        name: "My workflow",
        steps: []
      )

    {:ok, view, html} = live(conn, ~p"/workflows/#{workflow.id}/edit")

    assert html |> Floki.find(".sortable-item") |> length() == 0

    assert view
           |> element(~s(div[phx-click="add_step"]))
           |> render_click()
           |> Floki.parse_fragment!()
           |> Floki.find(".sortable-item")
           |> length() == 1
  end

  test "slack reply shows valid options for reply to", %{conn: conn, organization: organization} do
    workflow =
      :workflow
      |> build(
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string}],
        steps: [
          build(:workflow_step,
            order: 0,
            name: "before",
            action: %SlackAction{slack_channel: "#reviews", message: "Please review this", link_text: "Review"}
          ),
          build(:workflow_step,
            order: 1,
            action: %SlackReplyAction{message: "this is a reply"}
          ),
          build(:workflow_step,
            order: 2,
            name: "after",
            action: %SlackAction{slack_channel: "#reviews", message: "Another slack message", link_text: "Review"}
          )
        ]
      )
      |> Devhub.Repo.insert!()

    {:ok, _view, html} = live(conn, ~p"/workflows/#{workflow.id}/edit")

    assert [
             {"select", _select_attrs,
              [{"option", [{"class", "bg-surface-3 text-gray-900"}, {"value", "before"}], ["before"]}]}
           ] =
             html |> Floki.parse_fragment!() |> Floki.find("#workflow_steps_1_action_0_reply_to_step_name")
  end
end
