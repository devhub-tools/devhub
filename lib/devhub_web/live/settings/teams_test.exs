defmodule DevHubWeb.Live.Settings.TeamsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Repo
  alias Devhub.Users.Team

  test "team flow", %{conn: conn, organization: organization} do
    %{id: organization_id} = organization
    assert {:ok, view, html} = live(conn, ~p"/settings/teams")

    assert html =~ "Teams"

    # add team
    assert view
           |> element(~s(form[data-testid=add-team-form]))
           |> render_submit(%{name: "Devops"}) =~ "Devops"

    assert [
             %Team{name: "Devops", organization_id: ^organization_id}
           ] = Repo.all(Team)

    # delete team
    view
    |> element(~s(button[phx-click="delete_team"]))
    |> render_click()

    assert [] = Repo.all(Team)
  end

  test "update team", %{conn: conn, organization: organization} do
    team = insert(:team, organization: organization)
    assert {:ok, view, html} = live(conn, ~p"/settings/teams")

    assert html =~ "team name"

    assert view
           |> element(~s(form[data-testid=update-team-form]))
           |> render_submit(%{name: "Devops2", team_id: team.id}) =~ "Devops2"

    html = render(view)
    refute html =~ "team name"
  end
end
