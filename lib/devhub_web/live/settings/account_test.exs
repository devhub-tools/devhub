defmodule DevhubWeb.Live.Settings.AccountTest do
  use DevhubWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization
  alias Devhub.Users.Schemas.Passkey
  alias Devhub.Users.User

  test "update organization", %{conn: conn, organization: organization} do
    assert {:ok, view, html} = live(conn, ~p"/settings/account")

    assert html =~ "Default organization"

    expect(Tesla.Adapter.Finch, :call, fn %{method: :patch, url: url}, _opts ->
      assert url == "https://licensing.devhub.cloud/installations/#{organization.installation_id}"
      TeslaHelper.response([])
    end)

    assert view
           |> element(~s(form[phx-change=update_organization]))
           |> render_change(%{organization: %{name: "My organization"}}) =~ "My organization"

    assert %Organization{name: "My organization"} = Repo.get(Organization, organization.id)
  end

  test "update user", %{conn: conn, user: user} do
    assert {:ok, view, html} = live(conn, ~p"/settings/account")

    assert html =~ "John Doe"

    assert view
           |> element(~s(form[phx-change=update_user]))
           |> render_change(%{user: %{name: "Michael"}}) =~ "Michael"

    assert %User{name: "Michael"} = Repo.get(User, user.id)

    # won't update with invalid name
    assert view
           |> element(~s(form[phx-change=update_user]))
           |> render_change(%{user: %{name: "test!@#"}}) =~ "Michael"

    assert %User{name: "Michael"} = Repo.get(User, user.id)
  end

  test "timezone", %{conn: conn, user: user} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/account")

    html = render_hook(view, "filter_timezones", %{name: "America"})
    assert html =~ "America/Denver"
    refute html =~ "UTC"

    render_hook(view, "select_timezone", %{id: "America/Denver"})
    assert %User{timezone: "America/Denver"} = Repo.get(User, user.id)

    assert render_hook(view, "clear_filter") =~ "UTC"
  end

  test "passkey flow", %{conn: conn} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/account")

    challenge =
      Map.put(
        Wax.new_registration_challenge(),
        :bytes,
        <<114, 113, 208, 120, 148, 6, 15, 203, 126, 119, 242, 163, 4, 163, 142, 2, 147, 143, 251, 89, 11, 91, 108, 102,
          228, 170, 76, 0, 110, 171, 153, 81>>
      )

    expect(Wax, :new_registration_challenge, fn -> challenge end)

    view
    |> element(~s(button[phx-click="start_passkey_registration"]))
    |> render_click()

    assert_push_event(view, "start_passkey_registration", %{})

    assert render_hook(view, "register_passkey", %{
             "attestationObject" =>
               "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYSZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2NdAAAAAPv8MAcVTk7MjAtuAgVX170AFN/DZdnLEeOcKy+YmYw5vK+Mcz0kpQECAyYgASFYIDnPxUHE2D2OxVxMjv9iHf+Yj4uE4FUw9OT+mt3otN8iIlggA5/+84UUHSgqf3IrseTYNoQ9SPMSFMKJDkGfKFDHVF8=",
             "clientDataJSON" =>
               ~s({"type":"webauthn.create","challenge":"cnHQeJQGD8t-d_KjBKOOApOP-1kLW2xm5KpMAG6rmVE","origin":"http://localhost:4000","crossOrigin":false}),
             "rawId" => "38Nl2csR45wrL5iZjDm8r4xzPSQ=",
             "type" => "public-key"
           }) =~ "Passkey setup on"

    [passkey] = Repo.all(Passkey)

    # fail to remove
    expect(Devhub.Users, :remove_passkey, fn _user, _passkey -> {:error, :user_id_mismatch} end)

    assert view
           |> element(~s(button[phx-click="remove_passkey"]))
           |> render_click() =~ "Failed to remove passkey"

    # successfully remove
    assert view
           |> element(~s(button[phx-click="remove_passkey"]))
           |> render_click() =~ "Passkey removed"

    refute Repo.get(Passkey, passkey.id)
  end

  test "failed to register passkey", %{conn: conn} do
    assert {:ok, view, _html} = live(conn, ~p"/settings/account")

    view
    |> element(~s(button[phx-click="start_passkey_registration"]))
    |> render_click()

    assert_push_event(view, "start_passkey_registration", %{})

    assert render_hook(view, "register_passkey", %{
             "attestationObject" =>
               "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViYSZYN5YgOjGh0NBcPZHZgW4/krrmihjLHmVzzuoMdl2NdAAAAAPv8MAcVTk7MjAtuAgVX170AFN/DZdnLEeOcKy+YmYw5vK+Mcz0kpQECAyYgASFYIDnPxUHE2D2OxVxMjv9iHf+Yj4uE4FUw9OT+mt3otN8iIlggA5/+84UUHSgqf3IrseTYNoQ9SPMSFMKJDkGfKFDHVF8=",
             "clientDataJSON" =>
               ~s({"type":"webauthn.create","challenge":"cnHQeJQGD8t-d_KjBKOOApOP-1kLW2xm5KpMAG6rmVE","origin":"http://localhost:4000","crossOrigin":false}),
             "rawId" => "38Nl2csR45wrL5iZjDm8r4xzPSQ=",
             "type" => "public-key"
           }) =~ "Failed to register passkey"
  end
end
