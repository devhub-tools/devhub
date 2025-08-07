defmodule Devhub.Integrations.GitHub.Jobs.SyncCommitTest do
  use Devhub.DataCase, async: true

  import ExUnit.CaptureLog

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.CommitFile
  alias Devhub.Integrations.GitHub.Jobs.SyncCommit

  test "job completes successfully" do
    organization = insert(:organization)
    Phoenix.PubSub.subscribe(Devhub.PubSub, "github_sync:#{organization.id}")

    insert(:integration, organization: organization, provider: :github, external_id: "1")

    repository =
      insert(:repository, organization: organization, name: "devhub", owner: "devhub-tools", enabled: true)

    commit = insert(:commit, organization: organization, repository_id: repository.id)

    expect(Client, :commit, fn _integration, _repository, sha ->
      assert commit.sha == sha

      TeslaHelper.response(
        body: %{
          "files" => [
            %{
              "filename" => "lib/devhub/integrations/github/jobs/sync_commit_test.exs",
              "additions" => 10,
              "deletions" => 5,
              "patch" => "patch",
              "status" => "modified"
            },
            %{
              "filename" => ".gitignore",
              "additions" => 1,
              "deletions" => 0,
              "patch" => "patch",
              "status" => "added"
            }
          ]
        }
      )
    end)

    assert capture_log(fn ->
             SyncCommit.perform(%Oban.Job{
               args: %{"commit_id" => commit.id}
             })
           end) =~ "Imported 2 files for commit #{commit.sha}"

    # doesn't reimport files if they already exist
    refute capture_log(fn ->
             SyncCommit.perform(%Oban.Job{
               args: %{"commit_id" => commit.id}
             })
           end) =~ "Imported"

    assert [
             %CommitFile{
               filename: ".gitignore",
               extension: ".gitignore",
               additions: 1,
               deletions: 0,
               patch: "patch",
               status: "added"
             },
             %CommitFile{
               filename: "lib/devhub/integrations/github/jobs/sync_commit_test.exs",
               extension: ".exs",
               additions: 10,
               deletions: 5,
               patch: "patch",
               status: "modified"
             }
           ] = CommitFile |> Repo.all() |> Enum.sort_by(& &1.filename)
  end
end
