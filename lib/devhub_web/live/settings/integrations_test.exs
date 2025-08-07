defmodule DevhubWeb.Live.Settings.IntegrationsTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Integrations

  test "slack", %{conn: conn, organization: organization} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/integrations")

    assert {:error, {:live_redirect, %{kind: :push, to: "/settings/integrations"}}} =
             view
             |> element(~s(form[phx-submit=save_slack_integration]))
             |> render_submit(%{"integration" => %{"bot_token" => "bot-token"}})

    assert {:ok, %{access_token: json}} = Integrations.get_by(organization_id: organization.id, provider: :slack)
    assert %{"bot_token" => "bot-token"} = Jason.decode!(json)
  end
end
