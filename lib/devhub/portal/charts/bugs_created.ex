defmodule Devhub.Portal.Charts.BugsCreated do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  use DevhubWeb, :html

  import Devhub.Portal.Utils.BugChartDatasets
  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Bugs created"

  @impl true
  def tooltip, do: "Total number of tickets created that have label type of bug."

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
      links: data.links,
      stacked: true,
      displayLegend: true
    }
  end

  @impl true
  def data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    date =
      case date_grouping do
        "day" -> opts[:date]
        "week" -> Timex.beginning_of_week(opts[:date])
        "month" -> Timex.beginning_of_month(opts[:date])
      end

    query =
      from [issue: i] in core_query(organization_id, opts),
        where:
          type(
            fragment(
              "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
              ^date_grouping,
              i.created_at,
              ^opts[:timezone]
            ),
            :date
          ) ==
            ^date,
        select: %{
          identifier: i.identifier,
          title: i.title,
          url: i.url,
          created_at: i.created_at,
          state: i.state,
          priority: i.priority_label,
          estimate: i.estimate
        },
        distinct: true,
        order_by: i.created_at

    query
    |> Storage.maybe_filter_team_through_linear(opts[:team_id])
    |> Repo.all()
  end

  @impl true
  def line_chart_data(_organization_id, _opts) do
    []
  end

  @impl true
  def bar_chart_data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from [issue: i] in core_query(organization_id, opts),
        select: %{
          date:
            type(
              fragment(
                "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
                ^date_grouping,
                i.created_at,
                ^opts[:timezone]
              ),
              :date
            ),
          count: count(1)
        },
        order_by: [1, 2]

    bug_chart_datasets(query, "bugs-created", opts)
  end

  def render_filters(assigns) do
    ~H"""
    <.input
      type="select"
      field={@form[:group_by]}
      options={[
        {"By priority", "priority"},
        {"By label", "label"}
      ]}
    />
    """
  end

  def render_data_table(assigns) do
    ~H"""
    <.table id="bugs-created-data" rows={@data}>
      <:col :let={i} label="Issue" class="w-1/3">
        <div class="pr-4">
          <p class="truncate">
            {i.title}
          </p>

          <p class="mt-1 text-xs text-gray-400">
            {i.identifier}
          </p>
        </div>
      </:col>
      <:col :let={i} label="Estimate" class="w-1/10">
        {i.estimate || "(1)"}
      </:col>
      <:col :let={i} label="Priority">
        {i.priority}
      </:col>
      <:col :let={i} label="State">
        <div
          :if={not is_nil(i.state)}
          class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset"
          style={"background-color: #{hex_to_rgba(i.state.color, 0.1)}; --tw-ring-color: #{hex_to_rgba(i.state.color, 0.2)}; color: #{i.state.color};"}
        >
          {i.state.name}
        </div>
      </:col>
      <:col :let={i} label="Created at">
        <div class="text-nowrap">
          <format-date date={i.created_at}></format-date>
        </div>
      </:col>
      <:col :let={i} class="w-1/10">
        <.link href={i.url} target="_blank" class="flex items-center justify-end gap-x-2">
          <.icon name="devhub-linear" class="size-6 fill-[#24292F]" />
          <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
            <.icon name="hero-chevron-right-mini" />
          </div>
        </.link>
      </:col>
    </.table>
    """
  end

  defp core_query(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    from i in Issue,
      as: :issue,
      join: l in assoc(i, :labels),
      on: l.type == :bug,
      as: :label,
      where: i.organization_id == ^organization_id,
      where: i.created_at >= ^start_date,
      where: i.created_at <= ^end_date
  end
end
