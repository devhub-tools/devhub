defmodule Devhub.Portal.Charts.CompletedTicketsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Portal.Charts.CompletedTickets

  test "line_chart_data/2" do
    %{id: organization_id} = organization = insert(:organization)

    %{id: user_id} =
      insert(:linear_user, organization: organization)

    %{id: team_id} = insert(:team, organization: organization)

    %{id: org_user_id} =
      insert(:organization_user, organization: organization, linear_user_id: user_id)

    insert(:team_member, organization_user_id: org_user_id, team_id: team_id)

    insert(:linear_issue,
      organization: organization,
      linear_user_id: user_id,
      created_at: ~U[2024-02-02 00:00:00Z],
      completed_at: ~U[2024-02-05 00:00:00Z],
      labels: [insert(:linear_label, type: :bug, organization: organization)]
    )

    insert(:linear_issue,
      organization: organization,
      linear_user_id: user_id,
      estimate: 1,
      created_at: ~U[2024-02-03 00:00:00Z],
      completed_at: ~U[2024-02-06 00:00:00Z],
      labels: [insert(:linear_label, type: :tech_debt, organization: organization)]
    )

    opts = [
      start_date: ~D[2024-01-01],
      end_date: ~D[2024-03-02],
      timezone: "America/Chicago",
      team_id: team_id
    ]

    assert %{
             labels: [~D[2024-01-29], ~D[2024-02-05]],
             datasets:
               [
                 %{data: [1, 1], label: "Story points"},
                 %{data: [0, 1], label: "Tickets with estimates"},
                 %{data: [1, 0], label: "Tickets without estimates"}
               ] = datasets
           } =
             data =
             CompletedTickets.line_chart_data(organization_id, opts)

    assert %{
             datasets: ^datasets,
             displayLegend: true,
             labels: ["Jan 29", "Feb 5"],
             links: ["/portal/metrics/completed-tickets/2024-01-29", "/portal/metrics/completed-tickets/2024-02-05"]
           } = CompletedTickets.line_chart_config(data)
  end
end
