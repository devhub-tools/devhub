defmodule Devhub.Portal.Charts do
  @moduledoc false
  use Nebulex.Caching

  def id(module) do
    module |> Module.split() |> List.last()
  end

  def build(socket, {module, data}) do
    socket
    |> Phoenix.LiveView.push_event(
      "create_chart",
      Map.merge(module.line_chart_config(data.line), %{id: id(module) <> "-line", type: "line"})
    )
    |> Phoenix.LiveView.push_event(
      "create_chart",
      Map.merge(module.bar_chart_config(data.bar), %{id: id(module) <> "-bar", type: "bar"})
    )
  end

  @decorate cacheable(
              cache: Devhub.Portal.Cache,
              opts: [ttl: to_timeout(minute: 15)]
            )
  def data(chart, organization_id, opts) do
    %{
      line: chart.line_chart_data(organization_id, opts),
      bar: chart.bar_chart_data(organization_id, opts),
      data: opts[:with_details] && chart.data(organization_id, opts)
    }
  end

  def labels(metric) do
    metric
    |> Enum.map(& &1.min)
    |> Enum.reverse()
    |> then(fn
      [last | rest] -> ["#{last}+" | rest]
      [] -> []
    end)
    |> Enum.reverse()
  end

  def create_datasets(data, chart_link, opts) do
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
      data
      |> Enum.group_by(fn data ->
        case opts[:group_by] do
          "dev" -> data.dev
          "team" -> data.team
          _other -> "All"
        end
      end)
      |> Enum.map(fn {group, values} ->
        group_data =
          Enum.map(date_range, fn date ->
            values |> Enum.find_value(Decimal.new("0"), &(&1.date == date && &1.metric)) |> Decimal.round()
          end)

        %{
          label: group,
          data: group_data
        }
      end)

    %{
      labels: Enum.map(date_range, &Timex.format!(&1, "{Mshort} {D}")),
      links: Enum.map(date_range, &"/portal/metrics/#{chart_link}/#{&1}"),
      datasets: datasets
    }
  end
end
