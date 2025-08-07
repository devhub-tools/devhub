defmodule Devhub.Portal.Charts.LinesChanged do
  @moduledoc false
  @behaviour Devhub.Portal.Charts.Behaviour

  use DevhubWeb, :html

  import Devhub.Utils.QueryFilter
  import Ecto.Query

  alias Devhub.Integrations.GitHub.CommitFile
  alias Devhub.Metrics.Storage
  alias Devhub.Repo
  alias DevhubWeb.Live.Portal.ChartData
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def title, do: "Lines of code changed"

  @impl true
  def tooltip, do: "Number of lines added plus deleted on commits made to the default branch."

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
      from [commit: c, github_user: gu] in core_query(organization_id, opts),
        join: repo in assoc(c, :repository),
        where:
          type(
            fragment(
              "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
              ^date_grouping,
              c.authored_at,
              ^opts[:timezone]
            ),
            :date
          ) ==
            ^date,
        select: %{
          authored_at: c.authored_at,
          message: c.message,
          additions: c.additions,
          deletions: c.deletions,
          repo: fragment("? || '/' || ?", repo.owner, repo.name),
          author: gu.username,
          sha: c.sha
        },
        distinct: true,
        order_by: c.authored_at

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
      from [commit: commit] in core_query(organization_id, opts),
        select: %{
          date:
            type(
              fragment(
                "date_trunc(?, ? at time zone 'UTC' at time zone ?)",
                ^date_grouping,
                commit.authored_at,
                ^opts[:timezone]
              ),
              :date
            )
        },
        order_by: 1

    query
    |> lines_changed_select(opts[:lines_changed_type])
    |> group_lines_by(opts[:group_by])
    |> query_filter(extension: {:in, opts[:selected_extensions]})
    |> Storage.maybe_filter_team_through_commit_author(opts[:team_id])
    |> Storage.maybe_filter_dev(opts[:dev])
    |> Repo.all()
    |> Devhub.Portal.Charts.create_datasets("lines-changed", opts)
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
    <.input
      type="select"
      field={@form[:line_changed_type]}
      prompt="Lines combined"
      options={[
        {"Additions only", "additions"},
        {"Deletions only", "deletions"}
      ]}
    />
    <div>
      <.multi_select
        form={@form}
        filtered_objects={@opts[:filtered_extensions] || @opts[:extensions]}
        selected_objects={@selected_extensions}
        placeholder="All extensions"
        select_action="select_extension"
        filter_action="filter_extensions"
      />
    </div>
    """
  end

  def render_data_table(assigns) do
    ~H"""
    <.table id="cycle-time-data" rows={@data}>
      <:col :let={commit} label="Commit" class="w-1/3">
        <div class="pr-4">
          <p class="truncate">
            {commit.message}
          </p>

          <p class="mt-1 text-xs text-gray-400">
            {commit.repo} ({String.slice(commit.sha, 0..6)})
          </p>
        </div>
      </:col>

      <:col :let={commit} label="Additions/Deletions" class="min-w-1/12">
        <div class="pr-4">
          <p>
            {commit.additions + commit.deletions} lines
          </p>
          <p class="mt-1 truncate text-xs text-gray-400">
            {commit.additions} added / {commit.deletions} deleted
          </p>
        </div>
      </:col>
      <:col :let={commit} label="Author">
        {commit.author}
      </:col>
      <:col :let={commit} label="Authored at">
        <format-date date={commit.authored_at}></format-date>
      </:col>
      <:col :let={commit} class="w-1/12">
        <.link
          href={"https://github.com/#{commit.repo}/commit/#{commit.sha}"}
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

  def filter_opts(organization_id, opts) do
    ext_query =
      from cf in core_query(organization_id, opts),
        select: cf.extension,
        distinct: true,
        order_by: cf.extension

    extensions = Repo.all(ext_query)

    [extensions: extensions]
  end

  def handle_event("filter_extensions", %{"name" => filter}, socket) do
    filtered_extensions = Enum.filter(socket.assigns.filter_opts.result[:extensions], &String.contains?(&1, filter))
    filter_opts = Keyword.put(socket.assigns.filter_opts.result, :filtered_extensions, filtered_extensions)

    socket |> assign(filter_opts: AsyncResult.ok(socket.assigns.filter_opts, filter_opts)) |> noreply()
  end

  def handle_event("select_all", _params, socket) do
    socket = assign(socket, selected_extensions: [])

    ChartData.handle_event("update_filters", %{"extensions" => ""}, socket)
  end

  def handle_event("select_extension", %{"id" => extension}, socket) do
    selected = socket.assigns.selected_extensions

    selected =
      if extension in selected do
        selected -- [extension]
      else
        [extension | selected]
      end

    socket = assign(socket, selected_extensions: selected)

    ChartData.handle_event("update_filters", %{"extensions" => Enum.join(selected, ",")}, socket)
  end

  def handle_event("clear_filter", _params, socket) do
    filter_opts = Keyword.delete(socket.assigns.filter_opts.result, :filtered_extensions)

    socket |> assign(filter_opts: AsyncResult.ok(socket.assigns.filter_opts, filter_opts)) |> noreply()
  end

  defp core_query(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    ignore_usernames =
      case Keyword.fetch!(opts, :github_integration) do
        %{settings: %{"ignore_usernames" => ignore_usernames}} -> ignore_usernames
        _not_set -> []
      end

    from cf in CommitFile,
      join: c in assoc(cf, :commit),
      as: :commit,
      join: a in assoc(c, :authors),
      join: gu in assoc(a, :github_user),
      as: :github_user,
      where: c.organization_id == ^organization_id,
      where: c.on_default_branch,
      where: c.authored_at >= ^start_date,
      where: c.authored_at <= ^end_date,
      where: gu.username not in ^ignore_usernames
  end

  defp lines_changed_select(query, type) do
    case type do
      "additions" ->
        select_merge(query, [cf], %{metric: sum(cf.additions)})

      "deletions" ->
        select_merge(query, [cf], %{metric: sum(cf.deletions)})

      _other ->
        select_merge(query, [cf], %{metric: sum(cf.additions + cf.deletions)})
    end
  end

  defp group_lines_by(query, group_by) do
    case group_by do
      "dev" ->
        from [github_user: gu] in query,
          select_merge: %{
            dev: gu.username
          },
          group_by: [1, 3]

      "team" ->
        from [github_user: gu] in query,
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
