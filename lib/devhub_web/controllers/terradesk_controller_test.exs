defmodule DevhubWeb.TerraDeskControllerTest do
  use DevhubWeb.ConnCase, async: true

  @tag unauthenticated: true
  test "POST /api/internal/terradesk/upload-plan", %{conn: conn} do
    workspace = insert(:workspace)
    plan = insert(:plan, output: nil, workspace: workspace)
    data = %{plan_id: plan.id}
    internal_token = Phoenix.Token.sign(DevhubWeb.Endpoint, "internal", data)

    upload = %Plug.Upload{path: "test/support/plan.out", filename: "plan.out"}

    assert conn
           |> put_req_header("x-internal-key", internal_token)
           |> post(~p"/api/internal/terradesk/upload-plan", %{"plan.out" => upload})
           |> response(200)

    assert Devhub.Repo.get(Devhub.TerraDesk.Schemas.Plan, plan.id).output == <<0>>
  end

  test "POST /api/internal/terradesk/download-plan", %{conn: conn} do
    workspace = insert(:workspace)
    plan = insert(:plan, output: <<0>>, workspace: workspace)

    data = %{plan_id: plan.id}
    internal_token = Phoenix.Token.sign(DevhubWeb.Endpoint, "internal", data)

    assert conn
           |> put_req_header("x-internal-key", internal_token)
           |> get(~p"/api/internal/terradesk/download-plan")
           |> response(200) == <<0>>
  end
end
