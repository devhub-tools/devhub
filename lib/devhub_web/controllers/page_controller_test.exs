defmodule DevhubWeb.PageControllerTest do
  use DevhubWeb.ConnCase, async: true

  test "GET /license-expired" do
    assert Phoenix.ConnTest.build_conn()
           |> get(~p"/license-expired")
           |> html_response(200) =~ "Your license has expired"
  end

  test "GET /no-license" do
    assert Phoenix.ConnTest.build_conn()
           |> get(~p"/no-license")
           |> html_response(200) =~ "No assigned license"
  end

  test "GET /not-authenticated" do
    assert Phoenix.ConnTest.build_conn()
           |> get(~p"/not-authenticated")
           |> html_response(200) =~ "Not authenticated"
  end
end
