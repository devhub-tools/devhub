defmodule DevhubWeb.Live.Portal.Dev do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Portal
  alias Devhub.Portal.Charts
  alias Phoenix.LiveView.AsyncResult

  def mount(params, _session, socket) do
    socket
    |> assign(
      page_title: "Devhub",
      charts: [
        Charts.CycleTime,
        Charts.FirstCommitToOpen,
        Charts.FirstCommitToMerge,
        Charts.PrSize,
        Charts.OpenToFirstReview,
        Charts.NumberOfComments,
        Charts.NumberOfReviewers
      ],
      github_user_id: params["id"],
      metrics: nil,
      start_date: nil,
      end_date: nil,
      data: AsyncResult.loading(),
      breadcrumbs: [
        %{title: "Users", path: ~p"/settings/users"},
        %{title: "Dev Metrics"}
      ]
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      start_date = start_date_from_params(params)
      end_date = end_date_from_params(socket.assigns.user.timezone, params)

      {:noreply,
       socket
       |> assign(
         start_date: start_date,
         end_date: end_date
       )
       |> fetch_data()}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.async_result :let={data} assign={@data}>
        <:loading>
          <div class="flex h-screen items-center justify-center">
            <div class="h-10 w-10">
              <.spinner />
            </div>
          </div>
        </:loading>
        <.page_header title={data.name}>
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
        <div :if={@metrics} class="mb-4 flex flex-col gap-y-4">
          <div class="bg-surface-1 rounded-lg">
            <div class="divide-alpha-4 grid grid-cols-1 gap-px divide-x sm:grid-cols-2 lg:grid-cols-6">
              <div :for={metric <- @metrics} class="p-4">
                <div class="text-sm/6 flex items-center gap-x-1 font-medium text-gray-500">
                  <div>{metric.name}</div>
                  <div class="tooltip tooltip-top">
                    <span class="bg-alpha-16 size-4 relative flex items-center justify-center rounded-full text-xs text-gray-600">
                      ?
                    </span>
                    <span class="tooltiptext w-64 p-2">{metric.tooltip}</span>
                  </div>
                </div>
                <p class="mt-2 flex items-baseline gap-x-2">
                  <span class="text-4xl font-semibold tracking-tight">
                    {metric.value}
                  </span>
                  <span class="text-sm text-gray-500">{metric.unit}</span>
                </p>
              </div>
            </div>
          </div>
        </div>
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
    data.charts_data
    |> Enum.reduce(socket, fn chart, socket_acc ->
      Charts.build(socket_acc, chart)
    end)
    |> assign(
      data: AsyncResult.ok(socket.assigns.data, data),
      metrics: [
        %{
          name: "Commits per day",
          value: data.commits_per_day,
          unit: "commits",
          tooltip: "Number of pushed commits divided by number of days between specified dates."
        },
        %{
          name: "Coding days",
          value: data.coding_days_per_week,
          unit: "days / week",
          tooltip: "Number of days per week where at least one commit was pushed."
        },
        %{name: "Total PRs", value: data.total_prs, unit: "PRs", tooltip: "Total closed and merged PRs."},
        %{
          name: "Merged PRs",
          value: "#{data.merged_vs_closed_prs}%",
          unit: "",
          tooltip: "Percentage of PRs that were merged divided by total PRs."
        },
        %{
          name: "PRs reviewed",
          value: data.prs_reviewed,
          unit: "PRs",
          tooltip: "Number of PRs you have left a review on."
        },
        %{
          name: "Time to review",
          value: data.time_to_review,
          unit: "hours",
          tooltip: "How long it takes for you on average as a reviewer to review a PR since it has been opened."
        }
      ]
    )
    |> noreply()
  end

  defp fetch_data(socket) do
    %{
      charts: charts,
      github_user_id: github_user_id,
      organization: organization,
      start_date: start_date,
      end_date: end_date,
      user: user
    } = socket.assigns

    start_async(socket, :data, fn ->
      {:ok, github_user} = GitHub.get_user(id: github_user_id)

      name =
        case github_user do
          %{organization_user: %{linear_user: %{name: name}}} -> name
          %{username: username} -> username
        end

      github_integration =
        case Integrations.get_by(organization_id: organization.id, provider: :github) do
          {:ok, integration} -> integration
          _error -> nil
        end

      {coding_days_per_week, commits_per_day} =
        Portal.commits(organization.id, github_user.username,
          timezone: user.timezone,
          start_date: start_date,
          end_date: end_date
        )

      %{
        count: total_prs,
        merged_prs: merged_prs
      } =
        Portal.pr_counts(organization.id, github_user.username,
          timezone: user.timezone,
          start_date: start_date,
          end_date: end_date
        )

      %{
        prs_reviewed: prs_reviewed,
        time_to_review: time_to_review
      } =
        Portal.reviewed_prs(organization.id, github_user.username,
          timezone: user.timezone,
          start_date: start_date,
          end_date: end_date
        )

      merged_vs_closed_prs =
        if total_prs == 0 do
          0
        else
          (merged_prs / total_prs * 100) |> Float.round() |> trunc()
        end

      opts = [
        dev: github_user.username,
        start_date: start_date,
        end_date: end_date,
        timezone: user.timezone,
        github_integration: github_integration
      ]

      charts_data =
        Map.new(charts, fn chart ->
          {chart, Charts.data(chart, organization.id, opts)}
        end)

      %{
        charts_data: charts_data,
        coding_days_per_week: coding_days_per_week,
        commits_per_day: commits_per_day,
        merged_vs_closed_prs: merged_vs_closed_prs,
        name: name,
        prs_reviewed: prs_reviewed,
        time_to_review: time_to_review,
        total_prs: total_prs
      }
    end)
  end
end
