defmodule DevhubWeb.Live.Settings.LinearSettingsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.Linear.Jobs.Import
  alias Devhub.Integrations.Linear.Label
  alias Devhub.Integrations.Linear.Team
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  test "sync", %{conn: conn, organization: organization} do
    integration =
      insert(:integration,
        organization: organization,
        provider: :linear,
        access_token: Jason.encode!(%{access_token: "access_token"})
      )

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/linear")

    view
    |> element(~s(button[data-testid=sync-button]))
    |> render_click()

    assert_enqueued worker: Import, args: %{id: integration.id, days_to_sync: 30}, priority: 0
    assert_enqueued worker: Import, args: %{id: integration.id, days_to_sync: 365}, priority: 9

    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "linear_sync:#{organization.id}",
      {:import_status, %{message: "Importing issues", percentage: 75}}
    )

    assert view
           |> element(~s(div[data-testid=linear-import-status]))
           |> render() =~ "Importing issues"

    assert view
           |> element(~s(div[data-testid=linear-import-percentage]))
           |> render() =~ "width: 75%"

    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "linear_sync:#{organization.id}",
      {:import_status, %{message: "Import done", percentage: 100}}
    )

    # should display done button
    assert render(view) =~ "Your sync is complete"
  end

  test "assign linear team to team", %{conn: conn, organization: organization} do
    insert(:integration,
      organization: organization,
      provider: :linear,
      access_token: Jason.encode!(%{access_token: "access_token"})
    )

    team = insert(:team, organization: organization)
    linear_team = insert(:linear_team, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/linear")

    assert view
           |> element(~s(form[phx-change="update_team"]))
           |> render_change(%{id: linear_team.id, team: %{team_id: team.id}}) =~ "Team updated"

    assert Repo.get!(Team, linear_team.id).team_id == team.id
  end

  test "set label type", %{conn: conn, organization: organization} do
    insert(:integration,
      organization: organization,
      provider: :linear,
      access_token: Jason.encode!(%{access_token: "access_token"})
    )

    label = insert(:linear_label, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/linear")

    assert view
           |> element(~s(form[phx-change="update_label"]))
           |> render_change(%{id: label.id, label: %{type: "bug"}}) =~ "Label updated"

    assert Repo.get!(Label, label.id).type == :bug
  end

  test "update secrets", %{conn: conn, organization: organization} do
    integration =
      insert(:integration,
        organization: organization,
        provider: :linear,
        access_token: Jason.encode!(%{access_token: "access_token", webhook_secret: "webhook_secret"})
      )

    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/linear")

    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/integrations/linear"}}} =
             view
             |> element(~s(form[phx-submit="update_secrets"]))
             |> render_submit(%{access_token: "new_access_token", webhook_secret: "new_webhook_secret"})

    assert Repo.get!(Integration, integration.id).access_token ==
             ~s({"access_token":"new_access_token","webhook_secret":"new_webhook_secret"})
  end
end
