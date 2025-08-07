defmodule Devhub.TerraDesk.Actions.UpdatePlan do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Plan

  @callback update_plan(Plan.t(), map()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def update_plan(plan, params) do
    plan
    |> Plan.update_changeset(params)
    |> Repo.update()
  end
end
