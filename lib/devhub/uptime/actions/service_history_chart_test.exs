defmodule Devhub.Uptime.Actions.ServiceHistoryChartTest do
  use Devhub.DataCase, async: true

  alias Devhub.Uptime

  test "success" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    insert(:uptime_check_summary, service: service, date: Date.utc_today())
    insert(:uptime_check_summary, service: service, date: Date.add(Date.utc_today(), -1))
    insert(:uptime_check_summary, service: service, date: Date.add(Date.utc_today(), -2))

    ten = Decimal.new("10")
    twenty = Decimal.new("20")
    thirty = Decimal.new("30")
    forty = Decimal.new("40")
    sixty = Decimal.new("60")

    assert %{
             id: "service-history-chart",
             type: "line",
             unit: "ms",
             datasets: [
               %{
                 data: [
                   ^ten,
                   ^ten,
                   ^ten
                 ],
                 label: "DNS",
                 backgroundColor: "hsl(12 76% 61%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [
                   ^twenty,
                   ^twenty,
                   ^twenty
                 ],
                 label: "Connect",
                 backgroundColor: "hsl(173 58% 39%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [
                   ^thirty,
                   ^thirty,
                   ^thirty
                 ],
                 label: "TLS",
                 backgroundColor: "hsl(197 37% 24%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [
                   ^forty,
                   ^forty,
                   ^forty
                 ],
                 label: "First Byte",
                 backgroundColor: "hsl(43 74% 66%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [
                   ^sixty,
                   ^sixty,
                   ^sixty
                 ],
                 label: "Finish",
                 backgroundColor: "hsl(27 87% 67%)",
                 fill: true,
                 lineTension: 0.4
               }
             ],
             stacked: true
           } = Uptime.service_history_chart(service, Timex.shift(DateTime.utc_now(), months: -2), DateTime.utc_now())
  end

  test "works with no checks" do
    organization = insert(:organization)
    service = insert(:uptime_service, organization: organization)

    assert %{
             id: "service-history-chart",
             type: "line",
             unit: "ms",
             datasets: [
               %{
                 data: [],
                 label: "DNS",
                 backgroundColor: "hsl(12 76% 61%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [],
                 label: "Connect",
                 backgroundColor: "hsl(173 58% 39%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [],
                 label: "TLS",
                 backgroundColor: "hsl(197 37% 24%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [],
                 label: "First Byte",
                 backgroundColor: "hsl(43 74% 66%)",
                 fill: true,
                 lineTension: 0.4
               },
               %{
                 data: [],
                 label: "Finish",
                 backgroundColor: "hsl(27 87% 67%)",
                 fill: true,
                 lineTension: 0.4
               }
             ],
             stacked: true
           } = Uptime.service_history_chart(service, Timex.shift(DateTime.utc_now(), months: -2), DateTime.utc_now())
  end
end
