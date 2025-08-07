defmodule Devhub.Portal.Charts.NumberOfReviewers do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Number of reviewers"

  @impl true
  def tooltip, do: "The average number of reviewers per PR opened."

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
      labels: ["0", "1", "2", "3", "4+"],
      unit: "REVIEWERS"
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
      from prr in core_query(organization_id, opts),
        select: %{
          bucket:
            fragment(
              "width_bucket(?, 0, 4, 4)",
              prr.count
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

    pull_request_reviewers_query =
      from pr in PullRequest,
        join: repo in assoc(pr, :repository),
        where: repo.organization_id == ^organization_id,
        where: repo.enabled,
        left_join: prr in assoc(pr, :reviews),
        where: pr.opened_at >= ^start_date,
        where: pr.opened_at <= ^end_date,
        select: %{
          id: pr.id,
          author: pr.author,
          count: count(prr.author, :distinct)
        },
        group_by: [pr.id, pr.author]

    with_cte("pull_request_reviewers", "pull_request_reviewers", as: ^pull_request_reviewers_query)
  end
end
