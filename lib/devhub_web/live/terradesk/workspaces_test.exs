defmodule DevhubWeb.Live.TerraDesk.WorkspacesTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "has existing workspaces", %{conn: conn, organization: organization} do
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    insert(:plan,
      workspace: workspace,
      organization: organization,
      status: :planned,
      log: File.read!("test/support/terraform/plan-log.txt")
    )

    conn = get(conn, "/terradesk")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    assert html =~ "Workspaces"
    assert html =~ workspace.name
    assert html =~ "#{workspace.repository.owner}/#{workspace.repository.name}"
  end

  test "no workspaces", %{conn: conn} do
    conn = get(conn, "/terradesk")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    assert html =~ "No workspaces"
  end
end
