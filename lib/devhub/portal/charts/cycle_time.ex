defmodule Devhub.Portal.Charts.CycleTime do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  use DevhubWeb, :html

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Integrations.GitHub.User, as: GitHubUser
  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  @impl true
  def title, do: "Cycle time"

  @impl true
  def tooltip, do: "The time it takes to complete a pull request from opening to merging."

  @impl true
  def enable_bar_chart, do: true

  @impl true
  def enable_line_chart, do: true

  @impl true
  def line_chart_config(data) do
    %{
      data: Enum.map(data, &Decimal.to_integer(&1.cycle_time || Decimal.new("0"))),
      labels: Enum.map(data, &Timex.format!(&1.date, "{Mshort} {D}")),
      links: Enum.map(data, &"/portal/metrics/cycle-time/#{&1.date}")
    }
  end

  @impl true
  def bar_chart_config(data) do
    data =
      Enum.map(1..9, fn i -> Enum.find_value(data, 0, fn b -> b.bucket == i && b.count end) end)

    %{
      data: data,
      labels: ["<125", "125", "250", "375", "500", "625", "750", "875", "1000+"],
      unit: "HOURS"
    }
  end

  @impl true
  def data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from pr in core_query(organization_id, opts),
        join: repo in assoc(pr, :repository),
        left_join: gu in GitHubUser,
        on: gu.username == pr.author,
        left_join: ou in assoc(gu, :organization_user),
        left_join: lu in assoc(ou, :linear_user),
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
            ^opts[:date],
        select: %{
          user_name: lu.name,
          repo: fragment("? || '/' || ?", repo.owner, repo.name),
          author: pr.author,
          title: pr.title,
          number: pr.number,
          opened_at: pr.opened_at,
          merged_at: pr.merged_at,
          cycle_time:
            fragment(
              "round(extract(epoch from coalesce(?, now()) - ?)/3600)",
              pr.merged_at,
              pr.opened_at
            )
        },
        order_by: pr.merged_at

    query
    |> Storage.maybe_filter_team_through_github_user(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
  end

  @impl true
  def line_chart_data(organization_id, opts) do
    date_grouping = opts[:date_grouping] || "week"

    query =
      from pr in core_query(organization_id, opts),
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
          cycle_time:
            fragment(
              "round(avg(extract(epoch from coalesce(?, now()) - ?)/3600))",
              pr.merged_at,
              pr.opened_at
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
              "width_bucket(round(extract(epoch from coalesce(?, now()) - ?)/3600), 0, 1000, 8)",
              pr.merged_at,
              pr.opened_at
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
            {pr.user_name}
          </p>
          <p class="mt-1 truncate text-xs text-gray-400">
            {pr.author}
          </p>
        </div>
      </:col>
      <:col :let={pr} label="Opened at" class="text-nowrap">
        <format-date date={pr.opened_at}></format-date>
      </:col>
      <:col :let={pr} label="Merged at">
        <format-date :if={pr.merged_at} date={pr.merged_at}></format-date>
      </:col>
      <:col :let={pr} label="Cycle time" class="w-1/12">
        {pr.cycle_time}h
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
