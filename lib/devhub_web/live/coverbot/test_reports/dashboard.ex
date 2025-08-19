defmodule DevhubWeb.Live.Coverbot.TestReports.Dashboard do
  @moduledoc false
  use DevhubWeb, :live_view

  import DevhubWeb.Components.Coverbot.TestReports.TestSuiteRunStats

  alias Devhub.Coverbot

  def mount(_params, _session, socket) do
    test_suite_stats_list =
      Coverbot.list_test_report_stats(socket.assigns.organization)

    socket
    |> assign(test_suite_stats_list: test_suite_stats_list)
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <.page_header title="Test Reports">
        <:actions>
          <.link_button
            href="https://github.com/devhub-tools/coverbot-action"
            variant="text"
            target="_blank"
          >
            Setup instructions
          </.link_button>
        </:actions>
      </.page_header>
    </div>

    <div>
      <.link
        :if={Enum.empty?(@test_suite_stats_list)}
        id="empty-test-suites"
        navigate={~p"/settings/api-keys"}
        class="border-alpha-16 relative block w-full rounded-lg border-2 border-dashed p-12 text-center hover:border-alpha-24 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
      >
        <.icon name="hero-code-bracket" class="text-alpha-64 mx-auto h-20 w-20" />
        <span class="mt-2 block text-sm text-gray-600">
          No test reports uploaded yet, create an api key to get started.
        </span>
      </.link>
    </div>

    <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
      <div
        :for={test_suite_stats <- @test_suite_stats_list}
        class="bg-surface-1 ring-alpha-8 rounded-lg p-6"
      >
        <div id={test_suite_stats.test_suite.id <>"-card"}>
          <div class="grid grid-cols-2 place-content-between">
            <div class="justify-self-start">
              <p id={test_suite_stats.test_suite.id <>"-test-suite-header"} class="text-xl">
                {test_suite_stats.test_suite.repository.owner} /
                <span>{test_suite_stats.test_suite.repository.name}</span>
                / <span class="font-bold">{test_suite_stats.test_suite.name}</span>
              </p>
              <p class="text-alpha-64 mt-1 text-xs">
                Last run
                <format-date
                  date={test_suite_stats.last_test_suite_run.inserted_at}
                  format="relative-datetime"
                />
              </p>
            </div>
            <div
              id={test_suite_stats.test_suite.id <>"-execution-time"}
              class="flex items-center justify-self-end"
            >
              <.link_button
                variant="text"
                navigate={~p"/coverbot/test-reports/#{test_suite_stats.test_suite.id}"}
              >
                View details
              </.link_button>
              <div class="ml-5 flex items-center gap-2">
                <.icon name="hero-clock" />
                <p>
                  {test_suite_stats.last_test_suite_run.execution_time_seconds |> Decimal.round(2)} s
                </p>
              </div>
            </div>
          </div>
          <.test_suite_run_stats test_suite_run={test_suite_stats.last_test_suite_run} />
        </div>
      </div>
    </div>
    """
  end
end
