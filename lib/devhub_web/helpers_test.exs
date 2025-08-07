defmodule DevhubWeb.HelpersTest do
  use Devhub.DataCase, async: true

  alias DevhubWeb.Helpers

  test "save_preferences_and_patch" do
    uri = %URI{
      scheme: "http",
      authority: "localhost:4000",
      userinfo: nil,
      host: "localhost",
      port: 4000,
      path: "/portal/metrics/lines-changed/2024-10-28",
      query: nil,
      fragment: nil
    }

    user = insert(:user)
    socket = %Phoenix.LiveView.Socket{}
    socket = Phoenix.Component.assign(socket, user: user, uri: uri)

    assert %{
             assigns: %{
               user: %Devhub.Users.User{
                 preferences: %{
                   "filters" => %{
                     "lines-changed" => %{"extensions" => ".ex"}
                   }
                 }
               }
             },
             redirected: {:live, :patch, %{kind: :push, to: "/portal/metrics/lines-changed/2024-10-28?extensions=.ex"}}
           } = Helpers.save_preferences_and_patch(socket, "filters", "lines-changed", %{"extensions" => ".ex"})
  end
end
