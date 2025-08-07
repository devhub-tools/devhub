defmodule DevhubWeb.Live.TerraDesk.WorkspaceTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "loads", %{conn: conn, organization: organization} do
    workspace = insert(:workspace, organization: organization, repository: build(:repository, organization: organization))

    insert(:plan,
      workspace: workspace,
      organization: organization,
      status: :planned,
      log: File.read!("test/support/terraform/plan-log.txt")
    )

    conn = get(conn, "/terradesk/workspaces/#{workspace.id}")

    assert html_response(conn, 200)

    {:ok, _view, html} = live(conn)

    assert html =~ workspace.name
    assert html =~ "Planned"
  end
end
