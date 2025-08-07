defmodule Devhub.Portal.Utils.BugChartDatasets do
  @moduledoc false

  import Ecto.Query

  alias Devhub.Metrics.Storage
  alias Devhub.Repo

  def bug_chart_datasets(query, chart_path, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])
    date_grouping = opts[:date_grouping] || "week"

    date_range =
      case date_grouping do
        "day" -> Date.range(start_date, end_date)
        "week" -> Date.range(start_date, end_date, 7)
        "month" -> start_date |> Date.range(end_date) |> Enum.map(&Timex.beginning_of_month/1) |> Enum.uniq()
      end

    datasets =
      query
      |> handle_query_group_by(opts[:group_by])
      |> Storage.maybe_filter_team_through_linear(opts[:team_id])
      |> Repo.all()
      |> Enum.group_by(fn data ->
        case opts[:group_by] do
          "label" -> {data.label, data.color}
          _priority -> {data.label, data.priority}
        end
      end)
      |> Enum.map(fn {{label, color}, values} ->
        data =
          Enum.map(date_range, fn date ->
            values |> Enum.find_value(Decimal.new("0"), &(&1.date == date && &1.count)) |> Decimal.round()
          end)

        color =
          case color do
            "#" <> _hex -> color
            _other -> nil
          end

        %{
          label: label,
          backgroundColor: color,
          data: data
        }
      end)

    %{
      labels: Enum.map(date_range, &Timex.format!(&1, "{Mshort} {D}")),
      links: Enum.map(date_range, &"/portal/metrics/#{chart_path}/#{&1}"),
      datasets: datasets
    }
  end

  defp handle_query_group_by(query, group_by) do
    case group_by do
      "label" ->
        from [label: l] in query,
          select_merge: %{
            label: l.name,
            color: l.color
          },
          group_by: [1, l.name, l.color]

      _priority ->
        from i in query,
          select_merge: %{
            label: i.priority_label,
            priority: i.priority
          },
          group_by: [1, i.priority, i.priority_label]
    end
  end
end
