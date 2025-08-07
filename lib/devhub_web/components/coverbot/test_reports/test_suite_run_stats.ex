defmodule DevhubWeb.Components.Coverbot.TestReports.TestSuiteRunStats do
  @moduledoc false

  use DevhubWeb, :html

  attr :test_suite_run, :map, required: true

  def test_suite_run_stats(assigns) do
    ~H"""
    <div class="mx-auto mt-5">
      <div class="row-gap-8 grid place-items-center lg:grid-cols-3">
        <.stat
          id={@test_suite_run.id<>"-stat-number-of-tests"}
          title="Tests"
          value={@test_suite_run.number_of_tests}
        />
        <.stat
          id={@test_suite_run.id<>"-stat-number-of-failures"}
          title="Failures"
          value={@test_suite_run.number_of_failures}
        />
        <.stat
          id={@test_suite_run.id<>"-stat-number-of-skipped"}
          title="Skipped"
          value={@test_suite_run.number_of_skipped}
        />
      </div>
    </div>
    """
  end

  defp stat(assigns) do
    ~H"""
    <div id={@id} class="place-items-center">
      <div class="flex">
        <h6 class="text-4xl font-bold">
          {@value}
        </h6>
      </div>
      <p class="font-bold">{@title}</p>
    </div>
    """
  end
end
