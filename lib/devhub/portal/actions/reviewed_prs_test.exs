defmodule Devhub.Portal.Actions.ReviewedPRsTest do
  use Devhub.DataCase, async: true

  alias Devhub.Portal

  test "reviewed_prs/3" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = insert(:repository, organization_id: organization_id)

    %{id: pull_request_id, author: author} =
      insert(:pull_request,
        organization_id: organization_id,
        repository_id: repo_id,
        opened_at: ~U[2023-10-01 12:00:00Z],
        merged_at: ~U[2024-03-01 12:00:00Z]
      )

    insert(:pull_request_review,
      organization_id: organization_id,
      pull_request_id: pull_request_id,
      reviewed_at: ~U[2023-12-01 12:00:00Z]
    )

    opts = [
      timezone: "America/Chicago",
      start_date: ~D[2023-01-01],
      end_date: ~D[2024-04-01]
    ]

    assert %{prs_reviewed: 0, time_to_review: nil} = Portal.reviewed_prs(organization_id, author, opts)
  end
end
