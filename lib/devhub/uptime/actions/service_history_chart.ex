defmodule Devhub.Uptime.Actions.ServiceHistoryChart do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Repo
  alias Devhub.Uptime.Schemas.CheckSummary

  @colors %{
    dns: "hsl(12 76% 61%)",
    connect: "hsl(173 58% 39%)",
    tls: "hsl(197 37% 24%)",
    first_byte: "hsl(43 74% 66%)",
    finish: "hsl(27 87% 67%)"
  }

  @callback service_history_chart(Devhub.Uptime.Schemas.Service.t(), DateTime.t(), DateTime.t()) :: map()
  def service_history_chart(service, start_date, end_date) do
    data = data(service, start_date, end_date)

    %{
      id: "service-history-chart",
      type: "line",
      stacked: true,
      labels: Enum.map(data, &Timex.format!(&1.date, "{Mshort} {D}")),
      datasets: [
        %{
          label: "DNS",
          data: Enum.map(data, & &1.avg_dns_time),
          backgroundColor: @colors.dns,
          fill: true,
          lineTension: 0.4
        },
        %{
          label: "Connect",
          data: Enum.map(data, & &1.avg_connect_time),
          backgroundColor: @colors.connect,
          fill: true,
          lineTension: 0.4
        },
        %{
          label: "TLS",
          data: Enum.map(data, & &1.avg_tls_time),
          backgroundColor: @colors.tls,
          fill: true,
          lineTension: 0.4
        },
        %{
          label: "First Byte",
          data: Enum.map(data, & &1.avg_first_byte_time),
          backgroundColor: @colors.first_byte,
          fill: true,
          lineTension: 0.4
        },
        %{
          label: "Finish",
          data: Enum.map(data, & &1.avg_to_finish),
          backgroundColor: @colors.finish,
          fill: true,
          lineTension: 0.4
        }
      ],
      unit: "ms"
    }
  end

  defp data(service, start_date, end_date) do
    query =
      from c in CheckSummary,
        where: c.service_id == ^service.id,
        where: c.date >= ^start_date and c.date <= ^end_date,
        order_by: c.date

    Repo.all(query)
  end
end
