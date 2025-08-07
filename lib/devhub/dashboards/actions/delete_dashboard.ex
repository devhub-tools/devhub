defmodule Devhub.Dashboard.Actions.DeleteDashboard do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Repo

  @callback delete_dashboard(Dashboard.t()) :: {:ok, Dashboard.t()} | {:error, Ecto.Changeset.t()}
  def delete_dashboard(dashboard) do
    Repo.delete(dashboard)
  end
end
