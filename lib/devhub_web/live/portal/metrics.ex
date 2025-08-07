defmodule DevhubWeb.Live.Portal.Metrics do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Metrics.Utils
  alias Devhub.Portal.Charts
  alias Devhub.Users
  alias Phoenix.LiveView.AsyncResult

  def mount(_params, _session, socket) do
    organization_user = Devhub.Repo.preload(socket.assigns.organization_user, :teams)

    teams = [%{id: nil, name: "All Teams"}] ++ Users.list_teams(socket.assigns.organization.id)

    github_integration =
      case Integrations.get_by(organization_id: socket.assigns.organization.id, provider: :github) do
        {:ok, integration} -> integration
        _error -> nil
      end

    socket
    |> assign(
      page_title: "Devhub",
      organization_user: organization_user,
      charts: [
        Charts.CycleTime,
        Charts.PrSize,
        Charts.MergedPRs,
        Charts.LinesChanged,
        Charts.CompletedTickets,
        Charts.StoryPoints,
        Charts.FirstCommitToOpen,
        Charts.FirstCommitToMerge,
        Charts.OpenToFirstReview,
        Charts.NumberOfComments,
        Charts.NumberOfReviewers,
        Charts.BugsOutstanding,
        Charts.BugsCreated,
        Charts.BugsFixed
      ],
      selected_team_id: nil,
      selected_team_name: nil,
      start_date: nil,
      end_date: nil,
      github_integration: github_integration,
      teams: teams,
      filtered_teams: teams,
      data: AsyncResult.loading()
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      socket
      |> Utils.params_to_assigns(params)
      |> fetch_data()
      |> noreply()
    else
      noreply(socket)
    end
  end

  def render(%{github_integration: nil} = assigns) do
    ~H"""
    <div>
      <div class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24">
        <svg
          width="98"
          height="96"
          viewbox="0 0 98 96"
          xmlns="http://www.w3.org/2000/svg"
          class="size-12 mx-auto"
        >
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M48.854 0C21.839 0 0 22 0 49.217c0 21.756 13.993 40.172 33.405 46.69 2.427.49 3.316-1.059 3.316-2.362 0-1.141-.08-5.052-.08-9.127-13.59 2.934-16.42-5.867-16.42-5.867-2.184-5.704-5.42-7.17-5.42-7.17-4.448-3.015.324-3.015.324-3.015 4.934.326 7.523 5.052 7.523 5.052 4.367 7.496 11.404 5.378 14.235 4.074.404-3.178 1.699-5.378 3.074-6.6-10.839-1.141-22.243-5.378-22.243-24.283 0-5.378 1.94-9.778 5.014-13.2-.485-1.222-2.184-6.275.486-13.038 0 0 4.125-1.304 13.426 5.052a46.97 46.97 0 0 1 12.214-1.63c4.125 0 8.33.571 12.213 1.63 9.302-6.356 13.427-5.052 13.427-5.052 2.67 6.763.97 11.816.485 13.038 3.155 3.422 5.015 7.822 5.015 13.2 0 18.905-11.404 23.06-22.324 24.283 1.78 1.548 3.316 4.481 3.316 9.126 0 6.6-.08 11.897-.08 13.526 0 1.304.89 2.853 3.316 2.364 19.412-6.52 33.405-24.935 33.405-46.691C97.707 22 75.788 0 48.854 0z"
            fill="var(--gray-500)"
          />
        </svg>
        <h3 class="mt-4 font-semibold text-gray-900">GitHub not setup</h3>
        <p :if={@permissions.manager or @permissions.super_admin} class="text-sm text-gray-500">
          Setup GitHub in
          <.link_button navigate={~p"/settings/integrations"} variant="text" size="sm">
            settings
          </.link_button>.
        </p>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <.page_header title="Metrics">
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
          <.live_component
            :if={not is_nil(@github_integration)}
            id="filter"
            module={DevhubWeb.Components.Filter}
            uri={@uri}
            teams={@teams}
            start_date={@start_date}
            end_date={@end_date}
            selected_team_id={@selected_team_id}
            selected_team_name={@selected_team_name}
          />
        </:actions>
      </.page_header>
      <.async_result assign={@data}>
        <:loading>
          <div class="flex h-screen items-center justify-center">
            <div class="h-10 w-10">
              <.spinner />
            </div>
          </div>
        </:loading>
        <div id="charts" phx-hook="Chart" class="grid grid-cols-1 gap-4 2xl:grid-cols-2">
          <div
            :for={chart <- @charts}
            id={"#{Charts.id(chart)}-container"}
            class="bg-surface-1 ring-alpha-8 rounded-lg p-4"
          >
            <div class="mb-4 flex items-center gap-x-1">
              <h2 class="text-xl font-bold">{chart.title()}</h2>
              <div class="tooltip tooltip-right">
                <span class="bg-alpha-16 text-alpha-64 size-4 relative flex items-center justify-center rounded-full text-xs">
                  ?
                </span>
                <span class="tooltiptext w-64 p-2">{chart.tooltip()}</span>
              </div>
            </div>
            <div class="flex h-72">
              <div :if={chart.enable_line_chart()} class="w-2/3 flex-auto">
                <canvas id={"#{Charts.id(chart)}-line"}></canvas>
              </div>
              <div :if={chart.enable_bar_chart()} class="w-1/3 flex-auto">
                <canvas id={"#{Charts.id(chart)}-bar"}></canvas>
              </div>
            </div>
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  def handle_async(:data, {:ok, data}, socket) do
    data
    |> Enum.reduce(socket, fn chart, socket_acc ->
      Charts.build(socket_acc, chart)
    end)
    |> assign(data: AsyncResult.ok(socket.assigns.data, data))
    |> noreply()
  end

  defp fetch_data(socket) do
    %{
      charts: charts,
      organization: organization,
      start_date: start_date,
      end_date: end_date,
      user: user,
      selected_team_id: team_id,
      github_integration: github_integration
    } = socket.assigns

    start_async(socket, :data, fn ->
      opts = [
        team_id: team_id,
        start_date: start_date,
        end_date: end_date,
        timezone: user.timezone,
        github_integration: github_integration
      ]

      Map.new(charts, fn chart ->
        {chart, Charts.data(chart, organization.id, opts)}
      end)
    end)
  end
end
