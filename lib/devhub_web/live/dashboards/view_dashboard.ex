defmodule DevhubWeb.Live.Dashboards.ViewDashboard do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Dashboards
  alias Devhub.Permissions
  alias Devhub.QueryDesk

  require Logger

  def mount(%{"id" => dashboard_id}, _session, socket) do
    %{
      organization: %{id: organization_id},
      organization_user: organization_user
    } = socket.assigns

    with {:ok, dashboard} <- Dashboards.get_dashboard(id: dashboard_id, organization_id: organization_id),
         true <- not dashboard.restricted_access or Permissions.can?(:read, dashboard, organization_user) do
      socket
      |> assign(
        page_title: "Devhub",
        dashboard: dashboard,
        result: nil,
        query_running?: true,
        query_run_time: nil,
        query_start_time: System.monotonic_time(:millisecond),
        breadcrumbs: [
          %{title: "Dashboards", path: ~p"/dashboards"},
          %{title: dashboard.name}
        ]
      )
      |> run_queries_without_inputs()
      |> ok()
    else
      _error ->
        socket |> put_flash(:error, "Not authorized") |> push_navigate(to: ~p"/dashboards") |> ok()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <div class="flex flex-col gap-y-4">
        <div
          :for={panel <- @dashboard.panels}
          class="bg-surface-1 relative overflow-auto rounded-lg p-4"
        >
          <div class="mb-4 flex items-center justify-between">
            <h2 class="text-xl font-medium">{panel.title}</h2>
            <div class="flex items-center gap-x-2">
              <button id={"panel-#{panel.id}-copy-query-result"}>
                <.icon name="hero-square-2-stack" class="size-5" />
              </button>
              <span class="text-alpha-24 text-sm">|</span>
              <.button phx-click="export" phx-value-panel_id={panel.id} variant="text">
                Export
              </.button>
              <span class="text-alpha-24 text-sm">|</span>
              <.button variant="text" phx-click="run_query" phx-value-panel_id={panel.id}>
                Refresh
              </.button>
            </div>
          </div>

          <.form
            :let={f}
            :if={not Enum.empty?(panel.inputs)}
            for={%{}}
            phx-submit="run_query"
            class="mb-4"
          >
            <input type="hidden" name="panel_id" value={panel.id} />
            <div :for={input <- panel.inputs}>
              <.input field={f[input.key]} label={input.key} phx-debounce />
              <span class="text-alpha-64 mt-1 text-xs">
                {input.description}
              </span>
            </div>
            <div class="mt-4">
              <.button type="submit" variant="primary">Run query</.button>
            </div>
          </.form>

          <div class="border-alpha-8 overflow-auto rounded-lg border">
            <data-table id={"panel-#{panel.id}"} phx-hook="DataTable" />
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("run_query", variables, socket) do
    panel = Enum.find(socket.assigns.dashboard.panels, fn panel -> panel.id == variables["panel_id"] end)

    socket
    |> run_query(panel, variables)
    |> noreply()
  end

  def handle_event("export", %{"panel_id" => panel_id}, socket) do
    socket |> push_event("panel-#{panel_id}:custom_event", %{type: "export", data: %{}}) |> noreply()
  end

  def handle_event("query_finished", _params, socket) do
    # we don't need to handle this event on dashboards
    {:noreply, socket}
  end

  defp run_queries_without_inputs(socket) do
    socket.assigns.dashboard.panels
    |> Enum.filter(fn panel -> Enum.empty?(panel.inputs) end)
    |> Enum.reduce(socket, fn panel, socket ->
      run_query(socket, panel, %{})
    end)
  end

  defp run_query(socket, panel, variables) do
    query_string = QueryDesk.replace_query_variables(panel.details.query, variables)

    with {:ok, query} <-
           QueryDesk.create_query(%{
             organization_id: socket.assigns.organization_id,
             credential_id: panel.details.credential_id,
             query: query_string,
             is_system: true,
             user_id: socket.assigns.user.id
           }),
         {:ok, result, _query} <- QueryDesk.run_query(query) do
      result =
        result
        |> Map.from_struct()
        |> Map.update(:rows, [], fn rows ->
          Enum.map(rows || [], fn row ->
            Enum.map(row, &QueryDesk.format_field/1)
          end)
        end)

      socket
      |> clear_flash()
      |> push_event("panel-#{panel.id}:custom_event", %{type: "queryResult", data: result})
    else
      _error ->
        put_flash(socket, :error, "Failed to run query.")
    end
  end
end
