defmodule DevhubWeb.Plugs.VerifyInternalKeyTest do
  use DevhubWeb.ConnCase, async: true

  alias DevhubWeb.Plugs.VerifyInternalKey

  test "blocks invalid keys", %{conn: conn} do
    assert %{status: 401, state: :sent} =
             conn
             |> put_req_header("x-internal-key", "invalid")
             |> VerifyInternalKey.call([])
  end

  test "allows valid keys", %{conn: conn} do
    data = %{plan_id: "1", pid: self()}
    internal_token = Phoenix.Token.sign(DevhubWeb.Endpoint, "internal", data)

    assert %{status: nil, state: :unset, assigns: %{internal_key: ^data}} =
             conn
             |> put_req_header("x-internal-key", internal_token)
             |> VerifyInternalKey.call([])
  end
end
