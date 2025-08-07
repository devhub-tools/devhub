defmodule Devhub.TerraDesk.Actions.PlanSummary do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.TerraDesk.Schemas.Plan

  @callback plan_summary(Plan.t()) ::
              %{
                add: String.t(),
                change: String.t(),
                destroy: String.t()
              }
              | nil
  def plan_summary(%{log: log}) when is_binary(log) do
    case Regex.named_captures(
           ~r/(?<add>\d*) to add, (?<change>\d*) to change, (?<destroy>\d*) to destroy/,
           log
         ) do
      %{"add" => add, "change" => change, "destroy" => destroy} ->
        %{add: add, change: change, destroy: destroy}

      _no_match ->
        if String.contains?(log, "No changes.") do
          %{add: "0", change: "0", destroy: "0"}
        end
    end
  end

  def plan_summary(_plan), do: nil
end
