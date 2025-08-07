defmodule DevhubWeb.TerraDeskController do
  use DevhubWeb, :controller

  alias Devhub.TerraDesk

  def upload_plan(conn, params) do
    %{plan_id: plan_id} = conn.assigns.internal_key
    {:ok, plan} = TerraDesk.get_plan(id: plan_id)

    upload = params["plan.out"]
    plan_output = File.read!(upload.path)

    TerraDesk.update_plan(plan, %{output: plan_output})

    resp(conn, 200, "ok")
  end

  def download_plan(conn, _params) do
    %{plan_id: plan_id} = conn.assigns.internal_key
    {:ok, plan} = TerraDesk.get_plan(id: plan_id)

    resp(conn, 200, plan.output)
  end
end
