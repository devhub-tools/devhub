defmodule DevHubWeb.Live.Settings.AgentsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "agent flow", %{conn: conn, organization: organization} do
    agent = insert(:agent, organization: organization, name: "special agent")
    assert {:ok, view, html} = live(conn, ~p"/settings/agents")

    # checking name of agent in the table
    assert html =~ "special agent"

    # updating name of agent
    html =
      view
      |> element(~s(form[data-testid="update_agent"]))
      |> render_submit(%{name: "agent_2", agent_id: agent.id})

    # checking name of agent in the table updated
    refute html =~ "special agent"
    assert html =~ "agent_2"

    # adding new agent
    assert view
           |> element(~s(form[data-testid="add_agent"]))
           |> render_submit(%{name: "the best agent"}) =~ "the best agent"
  end
end
