defmodule Devhub.Integrations.GitHub.Actions.ImportReviewTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.PullRequestReview

  test "import review" do
    organization = insert(:organization)
    %{id: repo_id} = insert(:repository, organization: organization)

    %{id: pull_request_id} =
      insert(:pull_request, repository_id: repo_id, organization: organization)

    attrs = %{
      github_id: "github id",
      author: "author",
      reviewed_at: ~U[2016-05-24 13:26:08Z],
      pull_request_id: pull_request_id,
      organization_id: organization.id
    }

    assert {:ok,
            %PullRequestReview{
              github_id: "github id",
              author: "author",
              reviewed_at: ~U[2016-05-24 13:26:08Z],
              pull_request_id: ^pull_request_id
            }} = GitHub.import_review(attrs)
  end
end
