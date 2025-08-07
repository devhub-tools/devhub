defmodule DevhubWeb.Live.Portal.MyPortal do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Portal
  alias Devhub.Portal.Charts
  alias Devhub.QueryDesk
  alias Phoenix.LiveView.AsyncResult

  def mount(_params, _session, socket) do
    organization_user = Devhub.Repo.preload(socket.assigns.organization_user, :teams)

    socket
    |> assign(
      page_title: "Devhub",
      organization_user: organization_user,
      charts: [
        Charts.CycleTime,
        Charts.MergedPRs,
        Charts.PrSize,
        Charts.FirstCommitToOpen,
        Charts.FirstCommitToMerge,
        Charts.OpenToFirstReview,
        Charts.NumberOfComments
      ],
      metrics: nil,
      start_date: nil,
      end_date: nil,
      data: AsyncResult.loading()
    )
    |> ok()
  end

  def handle_params(params, _uri, socket) do
    if connected?(socket) do
      start_date = start_date_from_params(params)
      end_date = end_date_from_params(socket.assigns.user.timezone, params)

      socket
      |> assign(
        page_title: "Devhub",
        start_date: start_date,
        end_date: end_date
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
      <div
        :if={is_nil(@organization_user.github_user_id)}
        class="border-alpha-16 rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24"
      >
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
        <h3 class="mt-4 text-base font-semibold text-gray-900">Not connected</h3>
        <p :if={not (@permissions.manager or @permissions.super_admin)} class="text-sm text-gray-500">
          Reach out to your manager to setup your account.
        </p>
        <p :if={@permissions.manager or @permissions.super_admin} class="text-sm text-gray-500">
          Connect users to their GitHub accounts in
          <.link_button navigate={~p"/settings/users"} variant="text" size="sm">
            settings
          </.link_button>.
        </p>
      </div>

      <.async_result :let={data} :if={not is_nil(@organization_user.github_user_id)} assign={@data}>
        <:loading>
          <div class="flex items-center justify-center">
            <div class="h-10 w-10">
              <.spinner />
            </div>
          </div>
        </:loading>
        <div class="flex flex-col gap-y-4">
          <div class="bg-surface-1 rounded-lg">
            <div class="divide-alpha-4 grid grid-cols-1 gap-px divide-x sm:grid-cols-2 lg:grid-cols-6">
              <div :for={metric <- @metrics} class="p-4">
                <div class="text-sm/6 flex items-center gap-x-1 font-medium text-gray-500">
                  <div>{metric.name}</div>
                  <div class="tooltip tooltip-left">
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

          <div class="grid grid-cols-3 gap-x-4">
            <div>
              <.tasks tasks={data.tasks} />
            </div>
            <div>
              <.pull_requests pull_requests={data.pull_requests} />
            </div>
            <div>
              <.databases databases={data.databases} />
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
              <div class="flex h-72 gap-x-6">
                <div :if={chart.enable_line_chart()} class="w-2/3 flex-auto">
                  <canvas id={"#{Charts.id(chart)}-line"}></canvas>
                </div>
                <div :if={chart.enable_bar_chart()} class="w-1/3 flex-auto">
                  <canvas id={"#{Charts.id(chart)}-bar"}></canvas>
                </div>
              </div>
            </div>
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  defdelegate handle_async(key, value, socket), to: DevhubWeb.Live.Portal.Dev

  defp fetch_data(%{assigns: %{organization_user: %{github_user_id: nil}}} = socket), do: socket

  defp fetch_data(socket) do
    %{
      charts: charts,
      organization_user: organization_user,
      organization: organization,
      start_date: start_date,
      end_date: end_date,
      user: user
    } = socket.assigns

    start_async(socket, :data, fn ->
      {:ok, github_user} = GitHub.get_user(id: organization_user.github_user_id)

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

      tasks =
        if organization_user.linear_user_id do
          Integrations.get_tasks(
            [
              organization_id: organization.id,
              linear_user_id: organization_user.linear_user_id,
              state: {:type, ["triage", "unstarted", "started"]}
            ],
            limit: 10
          )
        else
          []
        end

      pull_requests =
        Integrations.get_pull_requests(
          [
            organization_id: organization.id,
            github_user_id: organization_user.github_user_id,
            state: "OPEN"
          ],
          limit: 10
        )

      databases = QueryDesk.list_databases(organization_user, filter: :favorites)

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
        databases: databases,
        merged_vs_closed_prs: merged_vs_closed_prs,
        name: name,
        prs_reviewed: prs_reviewed,
        pull_requests: pull_requests,
        tasks: tasks,
        time_to_review: time_to_review,
        total_prs: total_prs
      }
    end)
  end

  defp tasks(assigns) do
    ~H"""
    <div class="bg-surface-1 h-80 overflow-y-auto rounded-lg">
      <div class="divide-alpha-8 flex flex-col divide-y">
        <div class="flex-auto p-4">
          <span class="text-alpha-64 font-semibold">My Tasks</span>
        </div>
        <ul role="list" class="divide-alpha-4 divide-y">
          <li :for={task <- @tasks} class="hover:bg-alpha-4">
            <.link href={task.url} target="_blank" class="flex justify-between gap-x-4 px-4 py-5">
              <div class="flex min-w-0 gap-x-4">
                <div class="min-w-0 flex-auto">
                  <p class="truncate text-sm font-semibold">{task.title}</p>
                  <p class="mt-1 truncate text-xs text-gray-500">{task.identifier}</p>
                </div>
              </div>
              <div class="text-nowrap flex flex-col items-end justify-center">
                <p :if={not is_nil(task.state)}>
                  {task.state.name}
                </p>
                <p class="mt-1 text-xs text-gray-500">
                  Estimate: {task.estimate || "(1)"}
                </p>
              </div>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp pull_requests(assigns) do
    ~H"""
    <div class="bg-surface-1 h-80 overflow-y-auto rounded-lg">
      <div class="divide-alpha-8 flex flex-col divide-y">
        <div class="flex-auto p-4">
          <span class="text-alpha-64 font-semibold">My Open PRs</span>
        </div>
        <ul role="list" class="divide-alpha-4 divide-y">
          <li :for={pull_request <- @pull_requests} class="hover:bg-alpha-4">
            <.link
              href={"https://github.com/#{pull_request.repository.owner}/#{pull_request.repository.name}/pull/#{pull_request.number}"}
              target="_blank"
              class="flex items-center justify-between gap-x-4 px-4 py-5"
            >
              <div class="flex min-w-0">
                <div class="min-w-0 flex-auto">
                  <p class="truncate text-sm font-semibold">{pull_request.title}</p>
                  <p class="mt-1 truncate text-xs text-gray-400">
                    {pull_request.repository.owner}/{pull_request.repository.name}
                  </p>
                </div>
              </div>
              <div class="text-nowrap flex flex-col items-end justify-center">
                <p class="text-xs text-gray-400">
                  Opened
                </p>
                <format-date date={pull_request.opened_at} format="relative"></format-date>
              </div>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp databases(assigns) do
    ~H"""
    <div class="bg-surface-1 h-80 overflow-y-auto rounded-lg">
      <div class="divide-alpha-8 flex flex-col divide-y">
        <div class="flex-auto p-4">
          <span class="text-alpha-64 font-semibold">Databases</span>
        </div>
        <ul role="list" class="divide-alpha-4 divide-y">
          <li :for={database <- @databases} class="hover:bg-alpha-4">
            <.link
              href={~p"/querydesk/databases/#{database.id}/query"}
              target="_blank"
              class="flex items-center justify-between gap-x-4 px-4 py-5"
            >
              <div class="truncate">
                <div class="flex items-center gap-x-2 text-sm font-bold">
                  <div>{database.name}</div>
                  <div :if={database.group} class="flex items-center rounded bg-blue-200 px-2 py-1">
                    <span class="text-xs text-blue-900">{database.group}</span>
                  </div>
                </div>
                <div class="mt-1 flex flex-col">
                  <p class="truncate text-left text-xs text-gray-600">
                    <span class="text-alpha-64">database:</span> {database.database} ({database.adapter})
                  </p>
                </div>
              </div>
              <.button variant="outline">
                Connect
              </.button>
            </.link>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
