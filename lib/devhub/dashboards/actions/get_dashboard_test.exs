defmodule Devhub.Users.Actions.GetDashboardTest do
  use Devhub.DataCase, async: true

  alias Devhub.Dashboards
  alias Devhub.Dashboards.Schemas.Dashboard

  test "get_dashboard/1" do
    %{id: id} = insert(:dashboard)

    assert {:ok, %Dashboard{id: ^id}} = Dashboards.get_dashboard(id: id)
    assert {:error, :dashboard_not_found} = Dashboards.get_dashboard(id: "not-found")
  end
end
