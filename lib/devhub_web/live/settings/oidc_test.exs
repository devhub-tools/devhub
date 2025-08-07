defmodule DevHubWeb.Live.Settings.OIDCTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Repo
  alias Devhub.Users.OIDC

  test "oidc flow", %{conn: conn, organization: organization} do
    %{client_secret: client_secret} = insert(:oidc, organization: organization)
    assert {:ok, view, html} = live(conn, ~p"/settings/oidc")

    # make sure client secret isn't returned to the frontend
    assert [
             {"input",
              [
                {"type", _type},
                {"name", _name},
                {"id", _id},
                {"value", ""},
                {"class", _class},
                {"phx-debounce", "300"}
              ], []}
           ] = html |> Floki.parse_fragment!() |> Floki.find(~s(#oidc_client_secret))

    # checking uri before update
    assert html =~ "https://accounts.google.com/.well-known/openid-configuration"

    assert view
           |> element(~s(form[phx-submit=update_oidc]))
           |> render_submit(%{
             oidc: %{
               "client_id" => "778308f6-601f-4994-bf37-17485b272cef",
               "discovery_document_uri" => "https://accounts.google.com/.well-known/openid-configuration/2",
               "client_secret" => ""
             }
           }) =~ "https://accounts.google.com/.well-known/openid-configuration/2"

    # making sure client secret didn't update to empty string when no input was passed
    assert [%{client_secret: ^client_secret}] = Repo.all(OIDC)
  end

  @tag with_plan: :scale
  test "client secret updates when given input", %{conn: conn, organization: organization} do
    %{client_secret: client_secret} = insert(:oidc, organization: organization)

    assert {:ok, view, _html} = live(conn, ~p"/settings/oidc")

    assert [
             %{
               discovery_document_uri: "https://accounts.google.com/.well-known/openid-configuration",
               client_secret: ^client_secret
             }
           ] = Repo.all(OIDC)

    view
    |> element(~s(form[phx-submit=update_oidc]))
    |> render_submit(%{
      oidc: %{
        "client_id" => "778308f6-601f-4994-bf37-17485b272cef",
        "discovery_document_uri" => "https://accounts.google.com/.well-known/openid-configuration/2",
        "client_secret" => "new secret"
      }
    })

    # making sure both fields updated
    assert [
             %{
               discovery_document_uri: "https://accounts.google.com/.well-known/openid-configuration/2",
               client_secret: "new secret"
             }
           ] = Repo.all(OIDC)
  end

  @tag with_plan: :scale
  test "error updating oidc", %{conn: conn, organization: organization} do
    insert(:oidc, organization: organization)
    changeset = OIDC.changeset(%OIDC{}, %{})

    assert {:ok, view, _html} = live(conn, ~p"/settings/oidc")

    expect(Devhub.Users, :insert_or_update_oidc, fn _oidc, _params -> {:error, changeset} end)

    assert view
           |> element(~s(form[phx-submit=update_oidc]))
           |> render_submit(%{
             oidc: %{
               "client_id" => "778308f6-601f-4994-bf37-17485b272cef",
               "discovery_document_uri" => "https://accounts.google.com/.well-known/openid-configuration/2",
               "client_secret" => "secret"
             }
           }) =~ "Failed to update OIDC."
  end

  test "ensure oidc renders for first time", %{conn: conn} do
    assert {:ok, view, html} = live(conn, ~p"/settings/oidc")

    # check that login uri is present
    assert html =~ "http://localhost:4002/auth/oidc"

    # check that redirect uri is present
    assert html =~ "http://localhost:4002/auth/oidc/callback"

    # check to make sure all 3 inputs are visible
    assert view
           |> element(~s(form[phx-submit=update_oidc]))
           |> render()
           |> Floki.parse_document!()
           |> Floki.find("input")
           |> length() == 3
  end
end
