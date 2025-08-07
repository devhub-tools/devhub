defmodule Devhub.Portal.Charts.CompletedTickets do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  use DevhubWeb, :html

  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Completed tickets"

  @impl true
  def tooltip, do: "Number of completed tickets."

  @impl true
  def enable_bar_chart, do: false

  @impl true
  def enable_line_chart, do: true

  @impl true
  def line_chart_config(data) do
    %{
      datasets: data.datasets,
      labels: Enum.map(data.labels, &Timex.format!(&1, "{Mshort} {D}")),
      displayLegend: true,
      links: Enum.map(data.labels, &"/portal/metrics/completed-tickets/#{&1}")
    }
  end

  @impl true
  def bar_chart_config(_data) do
    %{}
  end

  @impl true
  def data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from i in core_query(organization_id, opts),
        where:
          type(
            fragment(
              "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
              ^date_grouping,
              i.completed_at,
              ^opts[:timezone]
            ),
            :date
          ) ==
            ^opts[:date],
        order_by: i.completed_at,
        preload: [:linear_user]

    query
    |> Storage.maybe_filter_team_through_linear_user(opts[:team_id])
    |> Repo.all()
  end

  @impl true
  def line_chart_data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from i in core_query(organization_id, opts),
        select: %{
          date:
            type(
              fragment(
                "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
                ^date_grouping,
                i.completed_at,
                ^opts[:timezone]
              ),
              :date
            ),
          points: sum(coalesce(i.estimate, 1)),
          count: filter(count(1), not is_nil(i.estimate)),
          not_estimated: filter(count(1), is_nil(i.estimate))
        },
        order_by: 1,
        group_by: 1

    data =
      query
      |> Storage.maybe_filter_team_through_linear_user(opts[:team_id])
      |> Repo.all()

    %{
      labels: Enum.map(data, & &1.date),
      datasets: [
        %{
          label: "Story points",
          data: Enum.map(data, & &1.points)
        },
        %{
          label: "Tickets with estimates",
          data: Enum.map(data, & &1.count)
        },
        %{
          label: "Tickets without estimates",
          data: Enum.map(data, & &1.not_estimated)
        }
      ]
    }
  end

  @impl true
  def bar_chart_data(_organization_id, _opts) do
    []
  end

  def render_data_table(assigns) do
    ~H"""
    <.table id="completed-tickets-data" rows={@data}>
      <:col :let={issue} label="Issue" class="w-1/3">
        <div class="pr-4 pl-2">
          <p>
            {issue.identifier}
          </p>

          <p class="text-wrap mt-1 text-xs text-gray-400">
            {issue.title}
          </p>
        </div>
      </:col>
      <:col :let={issue} label="User" class="min-w-1/12">
        <div class="pr-4">
          {issue.linear_user && issue.linear_user.name}
        </div>
      </:col>
      <:col :let={issue} label="Estimate" class="w-1/12">
        {issue.estimate || "(1)"}
      </:col>
      <:col :let={issue} label="Started at">
        <format-date :if={issue.started_at} date={issue.started_at} />
      </:col>
      <:col :let={issue} label="Completed at">
        <format-date :if={issue.completed_at} date={issue.completed_at} />
      </:col>
      <:col :let={issue} class="w-1/12">
        <.link href={issue.url} target="_blank" class="flex items-center justify-end pr-2">
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
      where: i.organization_id == ^organization_id,
      where: i.completed_at >= ^start_date,
      where: i.completed_at <= ^end_date
  end
end
