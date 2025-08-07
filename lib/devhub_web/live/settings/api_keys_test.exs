defmodule DevHubWeb.Live.Settings.ApiKeysTest do
  use DevhubWeb.ConnCase, async: true

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Devhub.ApiKeys.Schemas.ApiKey

  test "api key flow", %{conn: conn, organization: organization} do
    api_key = insert(:api_key, organization: organization)
    query = from a in ApiKey, where: is_nil(a.expires_at)

    assert {:ok, view, html} = live(conn, ~p"/settings/api-keys")

    # checking api key name in the table
    assert html =~ "Default"

    # adding new api key
    assert view
           |> element(~s(form[data-testid=add_api_key]))
           |> render_submit(%{name: "new api key", coverbot: true}) =~
             "Save your API key securely, you will not be able to retrieve it again."

    # deleting api key
    html =
      view
      |> element(~s(button[phx-value-id=#{api_key.id}]))
      |> render_click()

    # checking api key name in the table was deleted
    refute html =~ "Default"
    assert html =~ "new API key"

    assert [%{name: "new api key", permissions: [:coverbot]}] = Devhub.Repo.all(query)

    assert {:ok, view, _html} = live(conn, ~p"/settings/api-keys")

    # editing api key
    view
    |> element(~s(button[data-testid=edit-api-key]))
    |> render_click()

    view
    |> element(~s(form[data-testid=update_api_key]))
    |> render_change(%{name: "my api key", coverbot: true, querydesk_limited: true})

    view
    |> element(~s(form[data-testid=update_api_key]))
    |> render_submit()

    assert [%{name: "my api key", permissions: [:coverbot, :querydesk_limited]}] =
             Devhub.Repo.all(query)
  end
end
