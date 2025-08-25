defmodule DevhubWeb.Live.QueryDesk.QueryPlan do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.QueryDesk

  def mount(params, _session, socket) do
    {:ok, query} = QueryDesk.get_query(id: params["id"], organization_id: socket.assigns.organization.id)

    socket
    |> assign(
      query: query,
      plan: QueryDesk.parse_plan(query.plan),
      mode: "duration",
      selected_node_id: nil
    )
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-y-4">
      <div class="bg-surface-1 rounded-lg">
        <div class="divide-alpha-4 grid grid-cols-1 gap-px divide-x sm:grid-cols-2 lg:grid-cols-5">
          <div :for={stat <- @plan.stats} class="p-4">
            <div class="text-sm/6 flex items-center gap-x-1 font-medium text-gray-500">
              <div>{stat.name}</div>
            </div>
            <p class="mt-2 flex items-baseline gap-x-2">
              <span class="text-4xl font-semibold tracking-tight">
                {stat.value}
              </span>
              <span class="text-sm text-gray-500">{stat.unit}</span>
            </p>
          </div>
        </div>
      </div>
    </div>

    <.formatted_query
      id={@query.id}
      class="rounded-lg"
      background_color="bg-surface-1"
      query={String.replace(@query.query, ~r/^EXPLAIN\s*\([^)]*\)\s*/i, "")}
      adapter={@query.credential.database.adapter}
    />

    <div class="plan bg-surface-1 mt-4 w-full overflow-x-auto rounded-lg p-4">
      <div class="mb-1 flex items-start justify-between gap-x-4">
        <div>
          <p class="text-left text-sm text-gray-600">
            <span class="text-alpha-64">database:</span> {@query.credential.database.name}
          </p>
        </div>
        <div class="bg-alpha-4 divide-alpha-16 border-alpha-16 flex divide-x rounded border text-sm">
          <span
            phx-click="set_mode"
            phx-value-mode="duration"
            class={"#{@mode == "duration" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
          >
            Duration
          </span>
          <span
            phx-click="set_mode"
            phx-value-mode="rows"
            class={"#{@mode == "rows" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
          >
            Rows
          </span>
          <span
            phx-click="set_mode"
            phx-value-mode="cost"
            class={"#{@mode == "cost" && "bg-alpha-4"} cursor-pointer p-3 hover:bg-alpha-8"}
          >
            Cost
          </span>
        </div>
      </div>

      <ul>
        <li>
          <.plan_node plan={@plan} node={@plan} mode={@mode} selected_node_id={@selected_node_id} />
        </li>
      </ul>
    </div>
    """
  end

  def handle_event("toggle_details", %{"node" => node_id}, socket) do
    node_id = if node_id == socket.assigns.selected_node_id, do: nil, else: node_id

    socket
    |> assign(selected_node_id: node_id)
    |> noreply()
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    socket
    |> assign(mode: mode)
    |> noreply()
  end

  defp plan_node(assigns) do
    props =
      assigns.node
      |> Enum.filter(fn {key, _value} -> key != "Plans" and is_binary(key) end)
      |> Map.new(fn
        {key, value} when is_list(value) -> {key, Enum.join(value, ", ")}
        {key, value} -> {key, value}
      end)

    show_details = assigns.selected_node_id == assigns.node.id

    assigns =
      assign(assigns,
        props: props,
        show_details: show_details,
        show_query: false,
        width: (show_details && 25) || 18
      )

    ~H"""
    <div
      class="plan-node bg-surface-2 border-alpha-8 relative mb-2 inline-block cursor-pointer rounded border px-2 py-1 hover:bg-alpha-4"
      style={"width: #{@width}rem;"}
      phx-click="toggle_details"
      phx-value-node={@node.id}
    >
      <header class="mb-2 flex items-center justify-between">
        <span class="font-bold">{@node["Node Type"]}</span>
        <span class="ml-3 text-sm">
          {Float.round(@node.actual_duration, 2)}<span class="text-alpha-64">ms | </span>
          <span>
            {Float.round(@node.actual_duration / @plan.execution_time * 100) |> trunc}%
          </span>
        </span>
      </header>

      <div class="text-sm">
        <div :if={@node["Relation Name"]} class="text-left">
          <span class="text-alpha-64">on </span>
          <span :if={@node["Schema"]}>{@node["Schema"]}.</span>
          {@node["Relation Name"]}
          <span :if={@node["Alias"]}>({@node["Alias"]})</span>
        </div>

        <div :if={@node["Group Key"]} class="text-left">
          <span class="text-alpha-64">by</span> {@node["Group Key"]}
        </div>
        <div :if={@node["Sort Key"]} class="text-left">
          <span class="text-alpha-64">by</span> {@node["Sort Key"]}
        </div>
        <div :if={@node["Join Type"]} class="text-left">
          {@node["Join Type"]}
          <span class="text-alpha-64">join</span>
        </div>
        <div :if={@node["Index Name"]} class="text-left">
          <span class="text-alpha-64">
            using
          </span>
          {@node["Index Name"]}
        </div>
        <div :if={@node["Hash Condition"]} class="text-left">
          <span class="text-alpha-64">
            on
          </span>
          {@node["Hash Condition"]}
        </div>
        <div :if={@node["CTE Name"]} class="text-left">
          <span class="text-alpha-64">CTE</span> {@node["CTE Name"]}
        </div>
      </div>

      <div class="pt-1">
        <div class="bg-alpha-80 relative mt-2 mb-1 h-1 rounded">
          <span
            :if={@mode == "duration"}
            class="absolute top-0 left-0 h-full rounded text-left"
            style={"width: #{@node.actual_duration / @plan.max_duration * 16 }rem; background-color: hsl(#{(1 - @node.actual_duration / @plan.max_duration) * 100 * 1.2} 90% 40%);"}
          >
          </span>
          <span
            :if={@mode == "rows"}
            class="absolute top-0 left-0 h-full rounded text-left"
            style={"width: #{@node.actual_rows / @plan.max_rows * 16 }rem; background-color: hsl(#{(1 - @node.actual_rows / @plan.max_rows) * 100 * 1.2} 90% 40%);"}
          >
          </span>
          <span
            :if={@mode == "cost"}
            class="absolute top-0 left-0 h-full rounded text-left"
            style={"width: #{@node.actual_cost / @plan.max_cost * 16 }rem; background-color: hsl(#{(1 - @node.actual_cost / @plan.max_cost) * 100 * 1.2} 90% 40%);"}
          >
          </span>
        </div>
        <span class="block pt-1 text-left text-sm">
          <span class="text-alpha-64">{@mode}:</span>
          <span :if={@mode == "duration"}>{Float.round(@node.actual_duration, 2)}ms</span>
          <span :if={@mode == "rows"}>{@node.actual_rows} rows</span>
          <span :if={@mode == "cost"}>{Float.round(@node.actual_cost, 0) |> trunc}</span>
        </span>
      </div>

      <div class="tags">
        <span :if={@node.slowest_node?}>slowest</span>
        <span :if={@node.largest_node?}>largest</span>
        <span :if={@node.costliest_node?}>costliest</span>
      </div>

      <div
        :if={@node.planner_estimate_factor != 1}
        class="border-alpha-8 mt-2 w-full border-t pt-1 text-xs"
      >
        <span :if={@node.planner_estimate_direction == :over}>
          <strong>over</strong> estimated rows
        </span>
        <span :if={@node.planner_estimate_direction == :under}>
          <strong>under</strong> estimated rows
        </span>
        <span>by <strong>{@node.planner_estimate_factor}</strong>x</span>
      </div>

      <div :if={@show_details} class="text-sm">
        <div
          :if={description = node_description(String.upcase(@node["Node Type"]))}
          class="mt-4 break-normal break-words text-left text-sm"
        >
          <span class="bg-blue-400 px-1 font-medium">{@node["Node Type"]} Node</span>
          <span>{description}</span>
        </div>

        <div class="divide-alpha-8 mt-4 divide-y">
          <div :for={{key, value} <- @props} class="grid grid-cols-2 gap-x-2 py-1 text-left">
            <span class="text-alpha-64">{key}</span>
            <span>{value}</span>
          </div>
        </div>
      </div>
    </div>
    <ul :if={@node["Plans"]}>
      <li :for={node <- @node["Plans"]}>
        <.plan_node plan={@plan} node={node} selected_node_id={@selected_node_id} mode={@mode} />
      </li>
    </ul>
    """
  end

  # coveralls-ignore-start just returns descriptions
  defp node_description("LIMIT"), do: "returns a specified number of rows from a record set."
  defp node_description("SORT"), do: "sorts a record set based on the specified sort key."

  defp node_description("NESTED LOOP"),
    do:
      "merges two record sets by looping through every record in the first set and trying to find a match in the second set. All matching records are returned."

  defp node_description("MERGE JOIN"), do: "merges two record sets by first sorting them on a join key."

  defp node_description("HASH"),
    do: "generates a hash table from the records in the input recordset. Hash is used byHash Join."

  defp node_description("HASH JOIN"), do: "joins to record sets by hashing one of them (using a Hash Scan scan)."

  defp node_description("AGGREGATE"),
    do: "groups records together based on a GROUP BY or aggregate function (like sum())."

  defp node_description("HASHAGGREGATE"),
    do:
      "groups records together based on a GROUP BY or aggregate function (like sum()). Hash Aggregate uses a hash to first organize the records by a key."

  defp node_description("SEQ SCAN"),
    do:
      "finds relevant records by sequentially scanning the input record set. When reading from a table, Seq Scans (unlike Index Scans) perform a single read operation (only the table is read)."

  defp node_description("INDEX SCAN"),
    do:
      "finds relevant records based on an Index. Index Scans perform 2 read operations: one to read the index and another to read the actual value from the table."

  defp node_description("INDEX ONLY SCAN"),
    do:
      "finds relevant records based on an Index. Index Only Scans perform a single read operation from the index and do not read from the corresponding table."

  defp node_description("BITMAP HEAP SCAN"),
    do: "searches through the pages returned by theBitmap Index Scan for relevant rows."

  defp node_description("BITMAP INDEX SCAN"),
    do:
      "uses aBitmap Index (index which uses 1 bit per page) to find all relevant pages. Results of this node are fed to theBitmap Heap Scan."

  defp node_description("CTE SCAN"),
    do:
      "performs a sequential scan ofCommon Table Expression (CTE) query results. Note that results of a CTE are materialized (calculated and temporarily stored)."

  defp node_description(_type), do: ""
  # coveralls-ignore-stop
end
