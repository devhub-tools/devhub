defmodule Devhub.Dashboard.Actions.UpdateDashboard do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Repo

  @callback update_dashboard(Dashboard.t(), map()) ::
              {:ok, Dashboard.t()} | {:error, Ecto.Changeset.t()}
  def update_dashboard(dashboard, params) do
    dashboard
    |> Dashboard.changeset(params)
    |> Repo.update()
  end
end
