defmodule DevhubWeb.Live.Coverbot.TestReports.TestSuite do
  @moduledoc false
  use DevhubWeb, :live_view

  alias Devhub.Coverbot
  alias Phoenix.LiveView.AsyncResult

  def mount(%{"test_suite_id" => test_suite_id}, _session, socket) do
    {:ok, test_suite} = Coverbot.get_test_suite(test_suite_id)

    socket
    |> assign(
      test_suite: test_suite,
      page_title: "Test Suite",
      breadcrumbs: [
        %{title: "Test Suites", path: "/coverbot/test-reports"},
        %{
          title:
            test_suite.repository.owner <>
              " / " <> test_suite.repository.name <> " / " <> test_suite.name
        }
      ]
    )
    |> assign(
      flaky_tests: AsyncResult.loading(),
      skipped_tests: AsyncResult.loading()
    )
    |> assign_async([:flaky_tests], fn ->
      {:ok, %{flaky_tests: Coverbot.get_flaky_tests(test_suite_id, 10)}}
    end)
    |> assign_async([:skipped_tests], fn ->
      {:ok, %{skipped_tests: Coverbot.get_skipped_tests(test_suite_id)}}
    end)
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <div class="text-sm">
      <div id="flaky-tests" class="mb-4">
        <.page_header title="Flaky tests" />
        <.async_result :let={flaky_tests} assign={@flaky_tests}>
          <:loading>
            <div class="relative z-30 m-2 text-gray-900">Loading flaky tests</div>
          </:loading>
          <:failed :let={_failure}>
            <div class="relative z-30 m-2 text-gray-900">There was an error loading flaky tests</div>
          </:failed>
          <%= if Enum.empty?(flaky_tests) do %>
            <div class="relative z-30 m-2 text-gray-900">No flaky tests in the past 10 days</div>
          <% else %>
            <.table
              id="flaky-tests-data"
              rows={flaky_tests}
              row_click={&toggle_slide("##{test_drawer_id(&1, "flaky")}-content")}
            >
              <:col :let={test_run} label="Test" class="w-3/5">
                <p class="text-xs">{test_run.test_name}</p>
                <p class="text-xs text-gray-500">{test_run.class_name}</p>
              </:col>
              <:col :let={test_run} label="First time failed" class="w-1/5">
                <div class="flex items-center justify-between text-xs">
                  <format-date date={test_run.first_failure_at} format="relative-datetime" />
                  <div class="flex items-center gap-2">
                    <.link
                      href={"https://github.com/#{@test_suite.repository.owner}/#{@test_suite.repository.name}/commit/#{test_run.commit_sha}"}
                      target="_blank"
                    >
                      <.icon name="devhub-github" class="size-6 fill-[#24292F]" />
                    </.link>
                    <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                      <.icon name="hero-chevron-right-mini" />
                    </div>
                  </div>
                </div>
              </:col>
            </.table>
          <% end %>
        </.async_result>
      </div>

      <div id="skipped-tests" class="mb-4">
        <.page_header title="Skipped tests" />
        <.async_result :let={skipped_tests} assign={@skipped_tests}>
          <:loading>
            <div class="relative z-30 m-2 text-gray-900">Loading skipped tests</div>
          </:loading>
          <:failed :let={_failure}>
            <div class="relative z-30 m-2 text-gray-900">
              There was an error loading skipped tests
            </div>
          </:failed>
          <%= if Enum.empty?(skipped_tests) do %>
            <div class="relative z-30 m-2 text-gray-900">No skipped tests in the past 10 days</div>
          <% else %>
            <.table
              id="skipped-tests-data"
              rows={skipped_tests}
              row_click={&toggle_slide("##{test_drawer_id(&1, "skipped")}-content")}
            >
              <:col :let={test_run} label="Test" class="w-3/5">
                <p class="text-xs">{test_run.test_name}</p>
                <p class="text-xs text-gray-500">{test_run.class_name}</p>
              </:col>
              <:col :let={test_run} label="First time skipped" class="w-1/5">
                <div class="flex items-center justify-between text-xs">
                  <format-date date={test_run.test_suite_run.inserted_at} format="relative-datetime" />
                  <div class="flex items-center gap-2">
                    <.link
                      href={"https://github.com/#{@test_suite.repository.owner}/#{@test_suite.repository.name}/commit/#{test_run.test_suite_run.commit.sha}"}
                      target="_blank"
                    >
                      <.icon name="devhub-github" class="size-6 fill-[#24292F]" />
                    </.link>
                    <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
                      <.icon name="hero-chevron-right-mini" />
                    </div>
                  </div>
                </div>
              </:col>
            </.table>
          <% end %>
        </.async_result>
      </div>

      <div id="flaky-tests-drawer">
        <.async_result :let={flaky_tests} assign={@flaky_tests}>
          <:loading></:loading>
          <:failed :let={_failure}></:failed>
          <.drawer
            :for={test_run <- flaky_tests}
            id={test_drawer_id(test_run, "flaky")}
            width="w-[40rem]"
          >
            <div class="space-y-2 text-sm">
              <div class="flex items-center justify-center">
                <div class="text-center">
                  <h3 class="text-lg font-semibold text-gray-900">{test_run.test_name}</h3>
                  <p class="mt-1 text-sm text-gray-500">{test_run.class_name}</p>
                </div>
              </div>
              <div class="pt-6">
                <div>
                  <span class="font-semibold">Error message</span>:
                  <div class="bg-surface-3 mt-4 overflow-auto rounded p-4 text-sm">
                    <pre class="font-mono whitespace-pre-wrap">{String.trim(test_run.info.message)}</pre>
                  </div>
                </div>
                <div class="pt-4">
                  <span class="font-semibold">Stacktrace</span>:
                  <div class="bg-surface-3 mt-4 overflow-auto rounded p-4 text-sm">
                    <pre class="font-mono whitespace-pre-wrap">{String.trim(test_run.info.stacktrace)}</pre>
                  </div>
                </div>
              </div>
            </div>
          </.drawer>
        </.async_result>
      </div>

      <div id="skipped-tests-drawer">
        <.async_result :let={skipped_tests} assign={@skipped_tests}>
          <:loading></:loading>
          <:failed :let={_failure}></:failed>
          <.drawer
            :for={test_run <- skipped_tests}
            id={test_drawer_id(test_run, "skipped")}
            width="w-[40rem]"
          >
            <div class="space-y-2 text-sm">
              <div class="flex items-center justify-center">
                <div class="text-center">
                  <h3 class="text-lg font-semibold text-gray-900">{test_run.test_name}</h3>
                  <p class="mt-1 text-sm text-gray-500">{test_run.class_name}</p>
                </div>
              </div>
              <div class="pt-6">
                <span class="font-semibold">Info</span>
                <div class="bg-surface-3 mt-4 overflow-auto rounded p-4 text-sm">
                  <pre class="font-mono whitespace-pre-wrap">{String.trim(test_run.info.message)}</pre>
                </div>
              </div>
            </div>
          </.drawer>
        </.async_result>
      </div>
    </div>
    """
  end

  defp test_drawer_id(test_run, type) do
    # create a safe id by replacing special characters
    safe_test_name = String.replace(test_run.test_name, ~r/[^a-zA-Z0-9_-]/, "_")
    safe_class_name = String.replace(test_run.class_name, ~r/[^a-zA-Z0-9_-]/, "_")
    "#{type}-test-#{safe_test_name}-#{safe_class_name}-drawer"
  end
end
