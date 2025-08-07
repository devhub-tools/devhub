defmodule DevhubWeb.Live.Settings.GitHubSetupTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations.GitHub.Jobs.Import
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Repo

  test "setup flow", %{conn: conn, organization: organization} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations/github/setup")

    # type in github slug for app register link
    view
    |> element(~s(form[phx-change=update_github_app_form]))
    |> render_change(%{"org_slug" => "devhub-tools"}) =~ "https://github.com/organizations/devhub-tools/settings/apps/new"

    # register github app (happens externally and hits github controller
    insert(:github_app, organization: organization)
    insert(:integration, organization: organization, provider: :github, external_id: "1")

    repository =
      insert(:repository, organization: organization, name: "devhub", owner: "devhub-tools", enabled: false)

    insert(:repository, organization: organization, name: "licensing", owner: "devhub-tools", enabled: false)

    # after sync, redirects back to /setup
    assert {:ok, view, html} = live(conn, ~p"/settings/integrations/github/setup")

    assert html =~ "devhub-tools/devhub"

    # enable repository
    view
    |> element(~s(button[phx-value-id=#{repository.id}]))
    |> render_click()

    assert Repo.get(Repository, repository.id).enabled

    # start import
    view
    |> element(~s(button[phx-click=start_import]))
    |> render_click()

    assert_enqueued worker: Import, args: %{organization_id: organization.id, days_to_sync: 7}, priority: 0
    assert_enqueued worker: Import, args: %{organization_id: organization.id, days_to_sync: 90}, priority: 1
    assert_enqueued worker: Import, args: %{organization_id: organization.id, days_to_sync: 365}, priority: 9

    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "github_sync:#{organization.id}",
      {:import_status, %{message: "Importing devhub-tools/devhub", percentage: 50}}
    )

    assert view
           |> element(~s(div[data-testid=github-import-status]))
           |> render() =~ "Importing devhub-tools/devhub"

    assert view
           |> element(~s(div[data-testid=github-import-percentage]))
           |> render() =~ "width: 50%"

    refute has_element?(view, ~s(button[data-testid=import-complete-next]))

    Phoenix.PubSub.broadcast!(
      Devhub.PubSub,
      "github_sync:#{organization.id}",
      {:import_status, %{message: "Import done", percentage: 100}}
    )

    # should display done button
    assert render(view) =~ "/settings/integrations/github"
  end

  test "shows github connect button if user didn't finish setup on github", %{conn: conn, organization: organization} do
    app = insert(:github_app, organization: organization)

    assert {:ok, _view, html} = live(conn, ~p"/settings/integrations/github/setup")

    assert html =~ "https://github.com/apps/#{app.slug}/installations/new"
  end
end
