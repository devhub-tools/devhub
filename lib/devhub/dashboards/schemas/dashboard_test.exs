defmodule Devhub.Dashboards.Schemas.DashboardTest do
  use Devhub.DataCase, async: true

  alias Devhub.Dashboards.Schemas.Dashboard

  test "changeset/1" do
    assert %{errors: [], valid?: true} = Dashboard.changeset(%{organization_id: "org_123", name: "Dashboard 1"})

    assert %{errors: [{:organization_id, {"can't be blank", [validation: :required]}}], valid?: false} =
             Dashboard.changeset(%{name: "Dashboard 1"})

    assert %{errors: [{:name, {"can't be blank", [validation: :required]}}], valid?: false} =
             Dashboard.changeset(%{organization_id: "org_123"})
  end
end
