defmodule Devhub.Portal.Actions.PRCountsTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Portal

  test "pr_counts/3" do
    %{id: organization_id} = insert(:organization)
    %{id: repo_id} = insert(:repository, organization_id: organization_id, enabled: true)
    %{author: author} = insert(:pull_request, organization_id: organization_id, repository_id: repo_id)

    opts = [
      start_date: ~D[2023-10-01],
      end_date: ~D[2024-03-01],
      timezone: "America/Chicago"
    ]

    assert %{count: 1, closed_prs: 1, merged_prs: 0} = Portal.pr_counts(organization_id, author, opts)
  end
end
