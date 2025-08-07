defmodule DevhubWeb.Live.Workflows.DashboardTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Users.Schemas.OrganizationUser
  alias Devhub.Workflows

  test "admin can see add and edit buttons", %{conn: conn, organization: organization} do
    insert(:workflow, organization: organization, name: "My workflow")
    {:ok, view, html} = live(conn, ~p"/workflows")
    assert has_element?(view, ~s([data-testid="add-workflow-button"]))
    assert html =~ "edit"
    assert html =~ "My workflow"

    assert {:error, {:live_redirect, %{kind: :push, to: _redirect}}} =
             view
             |> element(~s(form[data-testid="add-workflow-form"]))
             |> render_submit(%{name: "Another workflow"})
  end

  test "empty state recommends workflows", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/workflows")

    assert html =~ "Create your first workflow"

    expect(Workflows, :create_workflow, fn %{
                                             name: "My first query workflow",
                                             steps: [%{action: %{__type__: "query"}}]
                                           } = params ->
      {:ok, build(:workflow, params)}
    end)

    assert {:error, {:live_redirect, %{kind: :push, to: _redirect}}} =
             view
             |> element(~s(li[phx-value-name="My first query workflow"]))
             |> render_click()
  end

  test "can create blank workflow from empty state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/workflows")

    expect(Workflows, :create_workflow, fn %{name: "My first workflow"} = params ->
      {:ok, build(:workflow, params)}
    end)

    assert {:error, {:live_redirect, %{kind: :push, to: _redirect}}} =
             view
             |> element(~s(button[phx-value-name="My first workflow"]))
             |> render_click()
  end

  test "non admin can't see add or edit buttons", %{conn: conn, user: user, organization: organization} do
    insert(:workflow, organization: organization, name: "My workflow")
    [organization_user] = user.organization_users
    organization_user |> OrganizationUser.changeset(%{permissions: %{super_admin: false}}) |> Devhub.Repo.update!()

    {:ok, view, html} = live(conn, ~p"/workflows")
    refute has_element?(view, ~s([data-testid="add-workflow-button"]))
    refute html =~ "edit"
    assert html =~ "My workflow"
  end

  test "handles create workflow failure", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/workflows")

    assert view
           |> element(~s(form[data-testid="add-workflow-form"]))
           |> render_submit(%{name: ""}) =~ "Failed to create workflow"
  end
end
