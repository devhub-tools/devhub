defmodule Devhub.Portal.Charts.PrSize do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Ecto.Query

  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "PR Size"

  @impl true
  def tooltip, do: "The average size (additions + deletions) of PRs opened."

  @impl true
  def enable_bar_chart, do: true

  @impl true
  def enable_line_chart, do: true

  @impl true
  def line_chart_config(data) do
    %{
      data: Enum.map(data, &Decimal.round(&1.size || "0")),
      labels: Enum.map(data, &Timex.format!(&1.week, "{Mshort} {D}"))
    }
  end

  @impl true
  def bar_chart_config(data) do
    data =
      Enum.map(1..9, fn i -> Enum.find_value(data, 0, fn b -> b.bucket == i && b.count end) end)

    %{
      data: data,
      labels: [
        "<75",
        "75",
        "150",
        "225",
        "300",
        "375",
        "450",
        "525",
        "600+"
      ],
      unit: "LINES OF CODE"
    }
  end

  @impl true
  def data(_organization_id, _opts) do
    []
  end

  @impl true
  def line_chart_data(organization_id, opts) do
    query =
      from pr in Storage.merged_prs_core_query(organization_id, opts),
        select: %{
          week: fragment("date_trunc('week', ? at time zone 'UTC' at time zone ?)", pr.merged_at, ^opts[:timezone]),
          size: avg(pr.additions + pr.deletions)
        },
        group_by: 1,
        order_by: 1

    query
    |> Storage.maybe_filter_team_through_github_user(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
  end

  @impl true
  def bar_chart_data(organization_id, opts) do
    query =
      from pr in Storage.merged_prs_core_query(organization_id, opts),
        select: %{
          bucket:
            fragment(
              "width_bucket(? + ?, 0, 600, 8)",
              pr.additions,
              pr.deletions
            ),
          count: count(1)
        },
        group_by: 1,
        order_by: 1

    query
    |> Storage.maybe_filter_team_through_github_user(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
  end
end
