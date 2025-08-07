defmodule Devhub.QueryDesk.Actions.ParsePlan do
  @moduledoc false

  @behaviour __MODULE__

  @callback parse_plan(map()) :: map()
  def parse_plan(plan) do
    {parsed_plan, max_rows, max_cost, max_duration} = process_node(plan["Plan"])

    stats = [
      %{
        name: "Execution time",
        value: plan["Execution Time"],
        unit: "ms"
      },
      %{
        name: "Planning time",
        value: Float.round(plan["Planning Time"], 2),
        unit: "ms"
      },
      %{
        name: "Max duration",
        value: Float.round(max_duration, 2),
        unit: "ms"
      },
      %{
        name: "Max rows",
        value: max_rows,
        unit: "rows"
      },
      %{
        name: "Max cost",
        value: Float.round(max_cost, 2),
        unit: nil
      }
    ]

    parsed_plan
    |> find_outlier_nodes(max_rows, max_cost, max_duration)
    |> Map.put(:stats, stats)
    |> Map.put(:execution_time, plan["Execution Time"])
    |> Map.put(:max_duration, max_duration)
    |> Map.put(:max_rows, max_rows)
    |> Map.put(:max_cost, max_cost)
  end

  defp process_node(node, max_rows \\ 0, max_cost \\ 0.0, max_duration \\ 0.0) do
    node =
      node
      |> Map.put(:id, Ecto.UUID.generate())
      |> Map.put(:show_details, false)
      |> calculate_planner_estimate()
      |> calculate_actuals()

    max_rows = max(max_rows, node.actual_rows)
    max_cost = max(max_cost, node.actual_cost)
    max_duration = max(max_duration, node.actual_duration)

    # Process child plans if they exist
    case node["Plans"] do
      nil ->
        {node, max_rows, max_cost, max_duration}

      plans ->
        {updated_plans, max_rows, max_cost, max_duration} =
          Enum.reduce(plans, {[], max_rows, max_cost, max_duration}, fn plan, {acc, mr, mc, md} ->
            {updated_plan, mr, mc, md} = process_node(plan, mr, mc, md)
            {[updated_plan | acc], mr, mc, md}
          end)

        {Map.put(node, "Plans", Enum.reverse(updated_plans)), max_rows, max_cost, max_duration}
    end
  end

  defp find_outlier_nodes(node, max_rows, max_cost, max_duration) do
    node =
      node
      |> Map.put(:slowest_node?, node.actual_duration == max_duration)
      |> Map.put(:largest_node?, node.actual_rows == max_rows)
      |> Map.put(:costliest_node?, node.actual_cost == max_cost)

    # Process child plans
    case Map.get(node, "Plans") do
      nil ->
        node

      plans ->
        updated_plans = Enum.map(plans, &find_outlier_nodes(&1, max_rows, max_cost, max_duration))
        Map.put(node, "Plans", updated_plans)
    end
  end

  defp calculate_actuals(node) do
    actual_duration = Map.get(node, "Actual Total Time", 0.0)
    actual_cost = Map.get(node, "Total Cost", 0.0)

    {actual_duration, actual_cost} =
      case Map.get(node, "Plans") do
        nil ->
          {actual_duration, actual_cost}

        plans ->
          Enum.reduce(plans, {actual_duration, actual_cost}, fn sub_plan, {duration, cost} ->
            if Map.get(sub_plan, "Node Type") == "CTE Scan" do
              {duration, cost}
            else
              {
                duration - Map.get(sub_plan, "Actual Total Time", 0.0),
                cost - Map.get(sub_plan, "Total Cost", 0.0)
              }
            end
          end)
      end

    actual_cost = max(0.0, actual_cost)
    # since time is reported for an individual loop, actual duration must be adjusted by number of loops
    actual_duration = actual_duration * Map.get(node, "Actual Loops", 1)

    node
    |> Map.put(:actual_duration, actual_duration)
    |> Map.put(:actual_cost, actual_cost)
    |> Map.put(:actual_rows, Map.get(node, "Actual Rows", 0))
  end

  defp calculate_planner_estimate(node) do
    actual_rows = Map.get(node, "Actual Rows", 0)
    plan_rows = Map.get(node, "Plan Rows", 0)

    estimate_factor =
      if plan_rows > 0 do
        actual_rows / plan_rows
      else
        0
      end

    {factor, direction} =
      cond do
        actual_rows == 0 ->
          {1.0, :exact}

        estimate_factor < 1 ->
          {plan_rows / actual_rows, :over}

        true ->
          {estimate_factor, :under}
      end

    node
    |> Map.put(:planner_estimate_factor, Float.round(factor, 2))
    |> Map.put(:planner_estimate_direction, direction)
  end
end
