defmodule Devhub.Dashboards do
  @moduledoc false
  @behaviour Devhub.Dashboard.Actions.CreateDashboard
  @behaviour Devhub.Dashboard.Actions.DeleteDashboard
  @behaviour Devhub.Dashboard.Actions.GetDashboard
  @behaviour Devhub.Dashboard.Actions.ListDashboards
  @behaviour Devhub.Dashboard.Actions.UpdateDashboard

  alias Devhub.Dashboard.Actions

  @impl Actions.CreateDashboard
  defdelegate create_dashboard(params), to: Actions.CreateDashboard

  @impl Actions.GetDashboard
  defdelegate get_dashboard(by), to: Actions.GetDashboard

  @impl Actions.ListDashboards
  defdelegate list_dashboards(organization_user), to: Actions.ListDashboards

  @impl Actions.UpdateDashboard
  defdelegate update_dashboard(dashboard, params), to: Actions.UpdateDashboard

  @impl Actions.DeleteDashboard
  defdelegate delete_dashboard(dashboard), to: Actions.DeleteDashboard
end
