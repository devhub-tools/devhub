defmodule Devhub.Portal.Charts.BugsOutstanding do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Devhub.Portal.Utils.BugChartDatasets
  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue

  @impl true
  def title, do: "Bugs outstanding"

  @impl true
  def tooltip, do: "Total number of open tickets that have label type of bug."

  @impl true
  def enable_bar_chart, do: true

  @impl true
  def enable_line_chart, do: false

  @impl true
  def line_chart_config(_data) do
    %{}
  end

  @impl true
  def bar_chart_config(data) do
    %{
      datasets: data.datasets,
      labels: data.labels,
      stacked: true,
      displayLegend: true
    }
  end

  @impl true
  def data(_organization_id, _opts) do
    []
  end

  @impl true
  def line_chart_data(_organization_id, _opts) do
    []
  end

  @impl true
  def bar_chart_data(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    query =
      from i in Issue,
        join:
          t in fragment(
            """
              SELECT generate_series(
                ?::date,
                ?::date,
                interval '1 week'
              ) AS day
            """,
            ^DateTime.to_date(start_date),
            ^DateTime.to_date(end_date)
          ),
        on: (is_nil(i.completed_at) or i.completed_at > t.day) and i.created_at < t.day,
        join: l in assoc(i, :labels),
        on: l.type == :bug,
        where: i.organization_id == ^organization_id,
        select: %{
          date: type(t.day, :date),
          count: count(1)
        },
        order_by: [1, 2]

    bug_chart_datasets(query, "bugs-fixed", opts)
  end
end
