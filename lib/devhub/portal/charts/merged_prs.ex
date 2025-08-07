defmodule Devhub.Portal.Charts.MergedPRs do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  use DevhubWeb, :html

  import Ecto.Query

  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Merged PRs"

  @impl true
  def tooltip, do: "Number of PRs merged."

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
      displayLegend: length(data.datasets) > 1
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
      from [pr, github_user: gu] in Storage.merged_prs_core_query(organization_id, opts),
        join: repo in assoc(pr, :repository),
        join: ou in assoc(gu, :organization_user),
        join: u in assoc(ou, :user),
        where:
          type(
            fragment(
              "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
              ^date_grouping,
              pr.merged_at,
              ^opts[:timezone]
            ),
            :date
          ) ==
            ^date,
        select: %{
          user: coalesce(u.name, u.email),
          author: pr.author,
          merged_at: pr.merged_at,
          number: pr.number,
          repo: fragment("? || '/' || ?", repo.owner, repo.name),
          title: pr.title
        },
        distinct: true,
        order_by: pr.merged_at

    query
    |> Storage.maybe_filter_team_through_commit_author(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
  end

  @impl true
  def line_chart_data(_organization_id, _opts) do
    nil
  end

  @impl true
  def bar_chart_data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from [pr] in Storage.merged_prs_core_query(organization_id, opts),
        select: %{
          date:
            type(
              fragment(
                "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
                ^date_grouping,
                pr.merged_at,
                ^opts[:timezone]
              ),
              :date
            ),
          metric: count(1)
        },
        order_by: 1

    query
    |> group_prs_by(opts[:group_by])
    |> Storage.maybe_filter_team_through_commit_author(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
    |> Devhub.Portal.Charts.create_datasets("merged-prs", opts)
  end

  def render_filters(assigns) do
    ~H"""
    <.input
      type="select"
      field={@form[:group_by]}
      prompt="No grouping"
      options={[
        {"By dev", "dev"},
        {"By team", "team"}
      ]}
    />
    """
  end

  def render_data_table(assigns) do
    ~H"""
    <.table id="cycle-time-data" rows={@data}>
      <:col :let={pr} label="Pull Request" class="w-1/3">
        <div class="pr-4">
          <p>
            {pr.repo} (PR {pr.number})
          </p>

          <p class="text-wrap mt-1 text-xs text-gray-400">
            {pr.title}
          </p>
        </div>
      </:col>
      <:col :let={pr} label="Author" class="min-w-1/12">
        <div class="pr-4">
          <p>
            {pr.user}
          </p>
          <p class="mt-1 truncate text-xs text-gray-400">
            {pr.author}
          </p>
        </div>
      </:col>
      <:col :let={pr} label="Merged at">
        <format-date :if={pr.merged_at} date={pr.merged_at}></format-date>
      </:col>
      <:col :let={pr} class="w-1/12">
        <.link
          href={"https://github.com/#{pr.repo}/pull/#{pr.number}"}
          target="_blank"
          class="flex items-center justify-end gap-x-2"
        >
          <.icon name="devhub-github" class="size-6 fill-[#24292F]" />
          <div class="bg-alpha-4 size-6 flex items-center justify-center rounded-md">
            <.icon name="hero-chevron-right-mini" />
          </div>
        </.link>
      </:col>
    </.table>
    """
  end

  defp group_prs_by(query, group_by) do
    case group_by do
      "dev" ->
        from [pr] in query,
          select_merge: %{
            dev: pr.author
          },
          group_by: [1, 3]

      "team" ->
        from [pr, github_user: gu] in query,
          join: ou in assoc(gu, :organization_user),
          join: m in assoc(ou, :team_members),
          join: t in assoc(m, :team),
          select_merge: %{
            team: t.name
          },
          group_by: [1, 3]

      _other ->
        group_by(query, 1)
    end
  end
end
