defmodule DevhubWeb.Live.Settings.LinearSetupTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations
  alias Devhub.Integrations.Linear.Jobs.Import

  test "setup flow", %{conn: conn, organization: organization} do
    assert {:ok, view, html} = live(conn, ~p"/settings/integrations/linear/setup")

    assert html =~ "https://linear.app/settings/api/applications/new"

    # click next to move on from instructions
    view
    |> element(~s(button[phx-click=next_step]))
    |> render_click() =~ "Next"

    # type in access token and webhook secret
    view
    |> element(~s(form[phx-submit=start_import]))
    |> render_submit(%{access_token: "access_token", webhook_secret: "webhook_secret"})

    assert {:ok, %{id: id, access_token: ~s({"access_token":"access_token","webhook_secret":"webhook_secret"})}} =
             Integrations.get_by(organization_id: organization.id, provider: :linear)

    assert_enqueued worker: Import, args: %{id: id, days_to_sync: 30}, priority: 0
    assert_enqueued worker: Import, args: %{id: id, days_to_sync: 365}, priority: 9

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
    assert render(view) =~ "/settings/integrations/linear"
  end
end
