defmodule DevhubWeb.Live.Workflows.WorkflowTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows
  alias Devhub.Workflows.Schemas.Run

  test "admin can see add and edit buttons", %{conn: conn, user: %{id: user_id}, organization: organization} do
    %{id: workflow_id} =
      workflow =
      insert(:workflow,
        organization: organization,
        name: "My workflow",
        inputs: [%{key: "user_id", type: :string, description: "User ID"}]
      )

    Workflows.run_workflow(workflow, %{"user_id" => user_id, "triggered_by_user_id" => user_id})
    {:ok, view, html} = live(conn, ~p"/workflows/#{workflow.id}")

    assert has_element?(view, ~s(button[data-testid="run-workflow"]))
    assert html =~ "edit"
    assert html =~ "My workflow"

    assert {:error, {:live_redirect, %{kind: :push, to: "/workflows/" <> ^workflow_id <> "/runs/" <> run_id}}} =
             view
             |> element(~s(form[data-testid="run-workflow"]))
             |> render_submit(%{user_id: user_id})

    assert {:ok, %Run{triggered_by_user_id: ^user_id, input: %{"user_id" => ^user_id}}} =
             Workflows.get_run(id: run_id, organization_id: organization.id)
  end

  test "non admin can't see edit button", %{conn: conn, user: user, organization: organization} do
    workflow = insert(:workflow, organization: organization, name: "My workflow")
    [organization_user] = user.organization_users
    organization_user |> OrganizationUser.changeset(%{permissions: %{super_admin: false}}) |> Devhub.Repo.update!()

    {:ok, view, html} = live(conn, ~p"/workflows/#{workflow.id}")
    assert has_element?(view, ~s(button[data-testid="run-workflow"]))
    refute html =~ "edit"
    assert html =~ "My workflow"
  end

  test "handles run workflow failure", %{conn: conn, organization: organization} do
    workflow =
      insert(:workflow, organization: organization, name: "My workflow", inputs: [%{key: "user_id", type: :integer}])

    {:ok, view, _html} = live(conn, ~p"/workflows/#{workflow.id}")

    assert view
           |> element(~s(form[data-testid="run-workflow"]))
           |> render_submit(%{user_id: "1.0"}) =~ "Failed to run workflow"
  end
end
