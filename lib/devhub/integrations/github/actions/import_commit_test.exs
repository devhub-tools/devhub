defmodule Devhub.Integrations.GitHub.Actions.ImportCommitTest do
  use Devhub.DataCase, async: true

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Repo

  test "import without author" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: repo_id} = insert(:repository, organization: organization)

    attrs = %{
      sha: "sha",
      message: "testing",
      repository_id: repo_id,
      authored_at: ~U[2016-05-24 13:26:08Z],
      organization_id: organization_id
    }

    assert %Commit{
             id: commit_id,
             sha: "sha",
             message: "testing",
             repository_id: ^repo_id,
             authored_at: ~U[2016-05-24 13:26:08Z]
           } = GitHub.import_commit(attrs, nil)

    assert_enqueued worker: GitHub.Jobs.SyncCommit, args: %{commit_id: commit_id}
  end

  test "import with author" do
    %{id: organization_id} = organization = insert(:organization)
    %{id: repo_id} = insert(:repository, organization: organization)

    attrs = %{
      sha: "sha",
      message: "testing",
      repository_id: repo_id,
      authored_at: ~U[2016-05-24 13:26:08Z],
      organization_id: organization_id
    }

    assert %Commit{
             id: id,
             sha: "sha",
             message: "testing",
             repository_id: ^repo_id,
             authored_at: ~U[2016-05-24 13:26:08Z]
           } = GitHub.import_commit(attrs, "michaelst")

    assert %{authors: [%{github_user: %{username: "michaelst"}}]} =
             Commit |> Repo.get(id) |> Repo.preload(authors: :github_user)
  end
end
