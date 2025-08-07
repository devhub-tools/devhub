defmodule Devhub.Portal.Charts.StoryPoints do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Ecto.Query

  alias Devhub.Integrations.Linear.Issue
  alias Devhub.Integrations.Linear.Label
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Story Point Percentages"

  @impl true
  def tooltip,
    do: "Percentage of time spent on tickets by type (if no estimate was assigned a default of 1 point is used)."

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
      labels: Enum.map(data.labels, &Timex.format!(&1, "{Mshort} {D}")),
      max: 100,
      displayLegend: true,
      stacked: true
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
    data =
      organization_id
      |> fetch_data(opts)
      |> Enum.group_by(& &1.date)
      |> Enum.map(fn {date, points} ->
        total_points = points |> Enum.map(& &1.points) |> Enum.sum()
        feature_points = Enum.find_value(points, 0, &(&1.type == "feature" && &1.points))
        bug_points = Enum.find_value(points, 0, &(&1.type == "bug" && &1.points))
        tech_debt_points = Enum.find_value(points, 0, &(&1.type == "tech_debt" && &1.points))

        if total_points > 0 do
          %{
            date: date,
            feature: feature_points |> Decimal.div(total_points) |> Decimal.mult(100),
            bug: bug_points |> Decimal.div(total_points) |> Decimal.mult(100),
            tech_debt: tech_debt_points |> Decimal.div(total_points) |> Decimal.mult(100)
          }
        else
          %{
            date: date,
            feature: 0,
            bug: 0,
            tech_debt: 0
          }
        end
      end)

    %{
      labels: Enum.map(data, & &1.date),
      datasets: [
        %{
          label: "Features %",
          data: Enum.map(data, & &1.feature),
          backgroundColor: "rgba(75,192,192,0.2)",
          borderColor: "rgba(75,192,192,1)",
          borderWidth: 1
        },
        %{
          label: "Bug %",
          data: Enum.map(data, & &1.bug),
          backgroundColor: "rgba(197,40,40,0.2)",
          borderColor: "rgba(197,40,40,1)",
          borderWidth: 1
        },
        %{
          label: "Tech Debt %",
          data: Enum.map(data, & &1.tech_debt),
          backgroundColor: "rgba(149,162,179,0.2)",
          borderColor: "rgba(149,162,179,1)",
          borderWidth: 1
        }
      ]
    }
  end

  defp fetch_data(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    subquery =
      from l in Label,
        join: il in "linear_issues_labels",
        on: il.label_id == l.id,
        where: l.type in [:bug, :tech_debt],
        where: l.organization_id == ^organization_id,
        select: %{issue_id: il.issue_id, type: l.type}

    query =
      from i in Issue,
        cross_join:
          t in fragment(
            """
              SELECT generate_series(
                ?::date,
                ?::date,
                interval '14 day'
              ) AS day
            """,
            ^DateTime.to_date(start_date),
            ^DateTime.to_date(end_date)
          ),
        left_join: l in subquery(subquery),
        on: i.id == l.issue_id,
        where: i.organization_id == ^organization_id,
        where: i.completed_at >= ^start_date,
        where: i.completed_at <= ^end_date,
        where: i.completed_at >= t.day,
        where: fragment("extract(day from ? - ?) < 14", i.completed_at, t.day),
        order_by: t.day,
        group_by: [1, 2],
        select: %{
          date: t.day,
          type: coalesce(l.type, "feature"),
          points: coalesce(sum(i.estimate), 1)
        }

    query
    |> Storage.maybe_filter_team_through_linear_user(opts[:team_id])
    |> Repo.all()
  end
end
