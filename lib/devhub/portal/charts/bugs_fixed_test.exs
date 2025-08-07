defmodule Devhub.Portal.Charts.BugsFixedTest do
  use Devhub.DataCase, async: true

  alias Devhub.Portal.Charts.BugsFixed

  test "bar_chart_data/2" do
    %{id: organization_id} = organization = insert(:organization)

    %{id: team_id} = insert(:team, organization: organization)
    %{id: linear_team_id} = insert(:linear_team, organization: organization, team_id: team_id)

    insert(:linear_issue,
      organization: organization,
      linear_team_id: linear_team_id,
      labels: [insert(:linear_label, type: :bug, organization: organization)],
      created_at: ~U[2024-02-10 12:00:00Z],
      completed_at: ~U[2024-02-29 12:00:00Z]
    )

    insert(:linear_issue,
      organization: organization,
      linear_team_id: linear_team_id,
      labels: [insert(:linear_label, type: :bug, organization: organization)],
      created_at: ~U[2024-01-10 12:00:00Z],
      completed_at: ~U[2024-01-29 12:00:00Z]
    )

    insert(:linear_issue,
      organization: organization,
      labels: [insert(:linear_label, type: :bug, organization: organization)],
      created_at: ~U[2024-01-02 12:00:00Z],
      completed_at: ~U[2024-01-05 12:00:00Z]
    )

    # unfiltered
    opts = [
      start_date: ~D[2024-01-01],
      end_date: ~D[2024-03-01],
      timezone: "America/Chicago"
    ]

    %{datasets: datasets} = data = BugsFixed.bar_chart_data(organization_id, opts)

    assert %{
             datasets: [
               %{
                 data: [
                   Decimal.new("1"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("1"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("1")
                 ],
                 label: "No Priority",
                 backgroundColor: nil
               }
             ],
             labels: ["Jan 1", "Jan 8", "Jan 15", "Jan 22", "Jan 29", "Feb 5", "Feb 12", "Feb 19", "Feb 26"],
             links: [
               "/portal/metrics/bugs-fixed/2024-01-01",
               "/portal/metrics/bugs-fixed/2024-01-08",
               "/portal/metrics/bugs-fixed/2024-01-15",
               "/portal/metrics/bugs-fixed/2024-01-22",
               "/portal/metrics/bugs-fixed/2024-01-29",
               "/portal/metrics/bugs-fixed/2024-02-05",
               "/portal/metrics/bugs-fixed/2024-02-12",
               "/portal/metrics/bugs-fixed/2024-02-19",
               "/portal/metrics/bugs-fixed/2024-02-26"
             ]
           } == data

    assert %{
             datasets: ^datasets,
             displayLegend: true,
             labels: ["Jan 1", "Jan 8", "Jan 15", "Jan 22", "Jan 29", "Feb 5", "Feb 12", "Feb 19", "Feb 26"]
           } = BugsFixed.bar_chart_config(data)

    # team_id filter
    opts = [
      start_date: ~D[2024-01-01],
      end_date: ~D[2024-03-01],
      timezone: "America/Chicago",
      team_id: team_id
    ]

    %{datasets: datasets} = data = BugsFixed.bar_chart_data(organization_id, opts)

    assert %{
             datasets: [
               %{
                 data: [
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("1"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("0"),
                   Decimal.new("1")
                 ],
                 label: "No Priority",
                 backgroundColor: nil
               }
             ],
             labels: ["Jan 1", "Jan 8", "Jan 15", "Jan 22", "Jan 29", "Feb 5", "Feb 12", "Feb 19", "Feb 26"],
             links: [
               "/portal/metrics/bugs-fixed/2024-01-01",
               "/portal/metrics/bugs-fixed/2024-01-08",
               "/portal/metrics/bugs-fixed/2024-01-15",
               "/portal/metrics/bugs-fixed/2024-01-22",
               "/portal/metrics/bugs-fixed/2024-01-29",
               "/portal/metrics/bugs-fixed/2024-02-05",
               "/portal/metrics/bugs-fixed/2024-02-12",
               "/portal/metrics/bugs-fixed/2024-02-19",
               "/portal/metrics/bugs-fixed/2024-02-26"
             ]
           } == data

    assert %{
             datasets: ^datasets,
             displayLegend: true,
             labels: ["Jan 1", "Jan 8", "Jan 15", "Jan 22", "Jan 29", "Feb 5", "Feb 12", "Feb 19", "Feb 26"]
           } = BugsFixed.bar_chart_config(data)
  end
end
