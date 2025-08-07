defmodule DevhubWeb.Live.Portal.ChartData do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Metrics.Utils
  alias Devhub.Portal.Charts
  alias Devhub.Users
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _session, socket) do
    organization_user = Devhub.Repo.preload(socket.assigns.organization_user, :teams)
    chart = chart(params["chart"])

    teams = [%{id: nil, name: "All Teams"}] ++ Users.list_teams(socket.assigns.organization.id)

    {:ok, date} = Date.from_iso8601(params["date"])

    socket
    |> assign(
      page_title: "Devhub",
      organization_user: organization_user,
      chart_key: params["chart"],
      chart: chart,
      date: date,
      teams: teams,
      filtered_teams: teams,
      selected_team_id: nil,
      selected_team_name: nil,
      start_date: nil,
      end_date: nil,
      data: AsyncResult.loading(),
      filter_opts: AsyncResult.loading(),
      date_grouping: "week",
      selected_extensions: [],
      group_by: nil,
      lines_changed_type: nil
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      preferences = socket.assigns.user.preferences["filters"][socket.assigns.chart_key]
      date_grouping = params["date_grouping"] || preferences["date_grouping"] || "week"

      date =
        case date_grouping do
          "day" -> socket.assigns.date
          "week" -> Timex.beginning_of_week(socket.assigns.date)
          "month" -> Timex.beginning_of_month(socket.assigns.date)
        end

      socket
      |> Utils.params_to_assigns(params)
      |> assign(
        date: date,
        date_grouping: date_grouping,
        group_by: params["group_by"] || preferences["group_by"],
        lines_changed_type: params["line_changed_type"] || preferences["line_changed_type"],
        selected_extensions: String.split(params["extensions"] || preferences["extensions"] || "", ",", trim: true)
      )
      |> fetch_data()
      |> noreply()
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <%!-- This is broken out so it doesn't impact the charts with re-rendering --%>
      <.page_header>
        <:header>
          <div class="flex items-center gap-x-1">
            <h2 class="text-xl font-bold">{@chart.title()}</h2>
            <div class="tooltip tooltip-right">
              <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
                ?
              </span>
              <span class="tooltiptext w-64 p-2">{@chart.tooltip()}</span>
            </div>
          </div>
        </:header>
        <:actions>
          <.dropdown
            :if={not is_nil(assigns[:start_date]) and not is_nil(assigns[:end_date])}
            id="date-picker"
          >
            <:trigger>
              <div class="text-alpha-64 border-alpha-24 mb-1 flex items-center gap-x-1 border-b text-sm">
                <format-date date={@start_date} format="date" />
                <.icon name="hero-arrow-long-right-mini text-alpha-40" class="size-4" />
                <format-date date={@end_date} format="date" />
              </div>
            </:trigger>
            <div class="ring-alpha-8 bg-surface-4 mt-1 w-48 rounded p-4 text-sm ring-1">
              <.form for={%{}} phx-change="set_date_filter">
                <div class="flex flex-col gap-y-4">
                  <div>
                    <.input name="start_date" type="date" value={@start_date} label="Start date" />
                  </div>
                  <div>
                    <.input name="end_date" type="date" value={@end_date} label="End Date" />
                  </div>
                </div>
              </.form>
            </div>
          </.dropdown>
        </:actions>
      </.page_header>
      <.async_result :let={data} assign={@data}>
        <:loading>
          <div class="flex h-screen items-center justify-center">
            <div class="h-10 w-10">
              <.spinner />
            </div>
          </div>
        </:loading>

        <div class="-mt-2 mb-4 flex items-center">
          <.live_component
            id="filter"
            module={DevhubWeb.Components.Filter}
            uri={@uri}
            teams={@teams}
            start_date={@start_date}
            end_date={@end_date}
            selected_team_id={@selected_team_id}
            selected_team_name={@selected_team_name}
          />

          <.form
            :let={f}
            for={
              %{
                "date_grouping" => @date_grouping,
                "group_by" => @group_by,
                "line_changed_type" => @lines_changed_type
              }
            }
            phx-change="update_filters"
          >
            <div class="ml-2 flex gap-x-2">
              <.input
                type="select"
                field={f[:date_grouping]}
                options={[{"Day", "day"}, {"Week", "week"}, {"Month", "month"}]}
              />
              <.async_result :let={opts} assign={@filter_opts}>
                <%= if function_exported?(@chart, :render_filters, 1) do %>
                  {@chart.render_filters(%{
                    form: f,
                    opts: opts,
                    selected_extensions: @selected_extensions
                  })}
                <% end %>
              </.async_result>
            </div>
          </.form>
        </div>

        <div id="charts" phx-hook="Chart" class="grid grid-cols-1 gap-4">
          <div id={"#{Charts.id(@chart)}-container"} class="bg-surface-1 ring-alpha-8 rounded-lg p-4">
            <div class="h-[40rem] flex">
              <div :if={@chart.enable_line_chart()} class="w-2/3 flex-auto">
                <canvas id={"#{Charts.id(@chart)}-line"}></canvas>
              </div>
              <div :if={@chart.enable_bar_chart()} class="w-1/3 flex-auto">
                <canvas id={"#{Charts.id(@chart)}-bar"}></canvas>
              </div>
            </div>
          </div>
          <div class="bg-surface-1 ring-alpha-8 rounded-lg">
            <h2 class="px-4 pt-4 text-xl font-bold">
              Data for {Timex.format!(@date, "{Mfull} {D}, {YYYY}")}
            </h2>
            <div class=" mt-6 overflow-y-auto px-4">
              {@chart.render_data_table(%{data: data})}
            </div>
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  def handle_event("update_filters", params, socket) do
    params =
      params
      |> Enum.reject(fn {key, _value} ->
        key == "_target" or String.starts_with?(key, "_unused")
      end)
      |> Map.new()

    socket |> save_preferences_and_patch("filters", socket.assigns.chart_key, params) |> noreply()
  end

  def handle_event(event, params, socket) do
    socket.assigns.chart.handle_event(event, params, socket)
  end

  def handle_async(:data, {:ok, data}, socket) do
    socket
    |> Charts.build({socket.assigns.chart, data.chart_data})
    |> assign(
      data: AsyncResult.ok(socket.assigns.data, data.chart_data.data),
      filter_opts: AsyncResult.ok(socket.assigns.filter_opts, data.filter_opts)
    )
    |> noreply()
  end

  defp chart("bugs-created"), do: Charts.BugsCreated
  defp chart("bugs-fixed"), do: Charts.BugsFixed
  defp chart("completed-tickets"), do: Charts.CompletedTickets
  defp chart("cycle-time"), do: Charts.CycleTime
  defp chart("lines-changed"), do: Charts.LinesChanged
  defp chart("merged-prs"), do: Charts.MergedPRs
  defp chart("open-to-first-review"), do: Charts.OpenToFirstReview

  defp fetch_data(socket) do
    %{
      chart: chart,
      end_date: end_date,
      organization: organization,
      selected_team_id: team_id,
      start_date: start_date,
      user: user,
      date: date,
      date_grouping: date_grouping,
      group_by: group_by,
      lines_changed_type: lines_changed_type,
      selected_extensions: selected_extensions
    } = socket.assigns

    start_async(socket, :data, fn ->
      github_integration =
        case Integrations.get_by(organization_id: organization.id, provider: :github) do
          {:ok, integration} -> integration
          _error -> nil
        end

      opts = [
        end_date: end_date,
        github_integration: github_integration,
        start_date: start_date,
        team_id: team_id,
        timezone: user.timezone,
        date: date,
        with_details: true,
        date_grouping: date_grouping,
        group_by: group_by,
        lines_changed_type: lines_changed_type,
        selected_extensions: selected_extensions
      ]

      filter_opts =
        if function_exported?(chart, :filter_opts, 2) do
          chart.filter_opts(organization.id, opts)
        else
          []
        end

      %{
        chart_data: Charts.data(chart, organization.id, opts),
        filter_opts: filter_opts
      }
    end)
  end
end
