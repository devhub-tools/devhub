defmodule Devhub.Portal.Charts.FirstCommitToMerge do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "First commit to merge"

  @impl true
  def tooltip, do: "The time it takes to merge a PR since the time the first commit was created."

  @impl true
  def enable_bar_chart, do: true

  @impl true
  def enable_line_chart, do: true

  @impl true
  def line_chart_config(data) do
    %{
      data: Enum.map(data, &Decimal.to_integer(&1.cycle_time || Decimal.new("0"))),
      labels: Enum.map(data, &Timex.format!(&1.week, "{Mshort} {D}"))
    }
  end

  @impl true
  def bar_chart_config(data) do
    %{
      data: Enum.map(data, & &1.count),
      labels: ["1", "12", "24", "36", "48", "60", "72+"],
      unit: "HOURS"
    }
  end

  @impl true
  def data(_organization_id, _opts) do
    []
  end

  @impl true
  def line_chart_data(organization_id, opts) do
    query =
      from pr in core_query(organization_id, opts),
        select: %{
          week:
            fragment(
              "date_trunc('week', ? at time zone 'UTC' at time zone ?)",
              pr.merged_at,
              ^opts[:timezone]
            ),
          cycle_time:
            fragment(
              "round(avg(extract(epoch from coalesce(?, now()) - ?)/3600))",
              pr.merged_at,
              pr.first_commit_authored_at
            )
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
      from pr in core_query(organization_id, opts),
        select: %{
          bucket:
            fragment(
              "width_bucket(extract(epoch from coalesce(?, now()) - ?)/3600, 0, 72, 6)",
              pr.merged_at,
              pr.first_commit_authored_at
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

  defp core_query(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    from pr in PullRequest,
      join: repo in assoc(pr, :repository),
      where: repo.organization_id == ^organization_id,
      where: repo.enabled,
      where: pr.merged_at >= ^start_date,
      where: pr.merged_at <= ^end_date
  end
end
