defmodule Devhub.Integrations.GitHub.Utils.UpsertPullRequestTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  import Devhub.Integrations.GitHub.Utils.UpsertPullRequest

  alias Devhub.Integrations.GitHub.PullRequest

  test "upsert_pull_request/1" do
    %{id: organization_id} = org = insert(:organization)

    %{id: repo_id} =
      insert(:repository, organization_id: organization_id, organization: org)

    attrs = %{
      number: 1,
      title: "title",
      state: "default state",
      author: "michaelst",
      opened_at: ~U[2016-05-24 13:26:08Z],
      organization_id: organization_id,
      repository_id: repo_id,
      is_draft: false,
      additions: 1,
      deletions: 1
    }

    assert {:ok,
            %PullRequest{
              id: id,
              number: 1,
              title: "title",
              state: "default state",
              author: "michaelst",
              opened_at: ~U[2016-05-24 13:26:08Z],
              repository_id: ^repo_id,
              organization_id: ^organization_id,
              additions: 1,
              deletions: 1
            }} = upsert_pull_request(attrs)

    attrs = %{attrs | title: "different title"}

    assert {:ok,
            %PullRequest{
              id: ^id,
              title: "different title"
            }} = upsert_pull_request(attrs)
  end
end
