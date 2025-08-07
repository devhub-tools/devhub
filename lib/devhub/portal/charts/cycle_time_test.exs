defmodule Devhub.Portal.Charts.CycleTimeTest do
  use Devhub.DataCase, async: true

  alias Devhub.Portal.Charts.CycleTime

  test "line_chart_data/2" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: repo_id} = insert(:repository, organization: organization, enabled: true)
    %{id: user_id, username: username} = insert(:github_user, organization: organization)

    %{id: team_id} = insert(:team, organization: organization)

    %{id: org_user_id} =
      insert(:organization_user, organization: organization, github_user_id: user_id)

    insert(:team_member, organization_user_id: org_user_id, team_id: team_id)

    insert(:pull_request,
      organization: organization,
      repository_id: repo_id,
      number: 45_556,
      title: "fixed bug",
      state: "good",
      author: username,
      first_commit_authored_at: ~U[2023-10-02 12:00:00Z],
      opened_at: ~U[2023-10-02 12:00:00Z],
      merged_at: ~U[2024-01-01 12:00:00Z],
      comments_count: 5
    )

    insert(:pull_request,
      organization: organization,
      repository_id: repo_id,
      number: 45_557,
      title: "fixed bug",
      state: "good",
      author: "some random person",
      first_commit_authored_at: ~U[2023-10-02 12:00:00Z],
      opened_at: ~U[2023-10-02 12:00:00Z],
      merged_at: ~U[2024-01-01 12:00:00Z],
      comments_count: 5
    )

    opts = [
      start_date: ~D[2023-09-01],
      end_date: ~D[2024-01-02],
      timezone: "America/Denver",
      week: ~U[2023-10-02 00:00:00Z],
      team_id: team_id
    ]

    assert [%{cycle_time: cycle_time, date: ~D[2024-01-01]}] =
             data =
             CycleTime.line_chart_data(organization_id, opts)

    assert cycle_time == Decimal.new("2184")

    assert %{
             data: [2184],
             labels: ["Jan 1"],
             links: ["/portal/metrics/cycle-time/2024-01-01"]
           } =
             CycleTime.line_chart_config(data)

    assert [%{bucket: 9, count: 1}] =
             data =
             CycleTime.bar_chart_data(organization_id, opts)

    assert %{
             data: [0, 0, 0, 0, 0, 0, 0, 0, 1],
             labels: ["<125", "125", "250", "375", "500", "625", "750", "875", "1000+"],
             unit: "HOURS"
           } =
             CycleTime.bar_chart_config(data)
  end
end
