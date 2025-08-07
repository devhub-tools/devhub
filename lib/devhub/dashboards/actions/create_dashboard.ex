defmodule Devhub.Dashboard.Actions.CreateDashboard do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Dashboards.Schemas.Dashboard
  alias Devhub.Repo

  @callback create_dashboard(map()) :: {:ok, Dashboard.t()} | {:error, Ecto.Changeset.t()}
  def create_dashboard(params) do
    params
    |> Dashboard.changeset()
    |> Repo.insert()
  end
end
