defmodule Devhub.Portal.Charts.NumberOfComments do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Metrics.Storage
  alias Devhub.Portal.Charts
  alias Devhub.Repo

  @impl true
  def title, do: "Number of comments"

  @impl true
  def tooltip, do: "The average number of comments per PR."

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
      data: Enum.map(data, & &1.count),
      labels: Charts.labels(data),
      unit: "COMMENTS"
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
    query =
      from pr in core_query(organization_id, opts),
        select: %{
          bucket:
            fragment(
              "width_bucket(?, 0, 5, 5)",
              pr.comments_count
            ),
          count: count(1),
          min: min(pr.comments_count)
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
      where: not is_nil(pr.merged_at) and not is_nil(pr.comments_count),
      where: pr.opened_at >= ^start_date,
      where: pr.opened_at <= ^end_date
  end
end
