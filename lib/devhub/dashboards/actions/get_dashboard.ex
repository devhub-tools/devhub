defmodule Devhub.Dashboard.Actions.GetDashboard do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Repo

  @callback get_dashboard([]) :: {:ok, %Dashboard{}} | {:error, :dashboard_not_found}
  def get_dashboard(by) do
    case Repo.get_by(Dashboard, by) do
      %Dashboard{} = dashboard -> {:ok, Repo.preload(dashboard, permissions: [:role, organization_user: :user])}
      nil -> {:error, :dashboard_not_found}
    end
  end
end
