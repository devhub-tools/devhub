defmodule Devhub.TerraDesk.Actions.GetPlan do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.TerraDesk.Schemas.Plan

  @callback get_plan(Keyword.t()) :: {:ok, Plan.t()} | {:error, :plan_not_found}
  def get_plan(by) do
    case Repo.get_by(Plan, by) do
      %Plan{} = plan ->
        {:ok,
         Repo.preload(plan,
           workspace: [:env_vars, :secrets, :workload_identity, :repository, :permissions, :organization]
         )}

      nil ->
        {:error, :plan_not_found}
    end
  end
end
