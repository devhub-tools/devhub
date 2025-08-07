defmodule Devhub.Portal.Actions.CommitsTest do
  @moduledoc false
  use Devhub.DataCase, async: true

  alias Devhub.Portal

  setup do
    organization = insert(:organization)
    repo = insert(:repository, organization_id: organization.id)
    github_user = insert(:github_user, organization_id: organization.id)

    %{
      organization: organization,
      repo: repo,
      github_user: github_user
    }
  end

  describe "commits/3" do
    test "author has no commits", %{organization: organization, github_user: github_user} do
      opts = [
        timezone: "America/Chicago",
        start_date: ~D[2023-12-20],
        end_date: ~D[2023-12-30]
      ]

      assert {0, 0} = Portal.commits(organization.id, github_user.username, opts)
    end

    test "author has no commits for date range",
         %{
           organization: organization,
           repo: repo,
           github_user: github_user
         } do
      %{id: commit_id} =
        commit =
        insert(:commit,
          authored_at: ~U[2024-01-01 12:00:00Z],
          repository_id: repo.id,
          organization_id: organization.id
        )

      insert(:commit_author,
        commit_id: commit_id,
        commit: commit,
        github_user_id: github_user.id
      )

      opts = [
        timezone: "America/Chicago",
        start_date: ~D[2023-12-20],
        end_date: ~D[2023-12-30]
      ]

      assert {0, 0} = Portal.commits(organization.id, github_user.username, opts)
    end

    test "author has commits for date range", %{
      organization: organization,
      repo: repo,
      github_user: github_user
    } do
      other_github_user = insert(:github_user, organization_id: organization.id, username: "other_user")

      other_user_commit =
        insert(:commit,
          authored_at: ~U[2023-12-25 12:00:00Z],
          repository_id: repo.id,
          organization_id: organization.id
        )

      insert(:commit_author,
        commit_id: other_user_commit.id,
        commit: other_user_commit,
        github_user_id: other_github_user.id
      )

      out_of_range_commit =
        insert(:commit,
          authored_at: ~U[2024-01-01 12:00:00Z],
          repository_id: repo.id,
          organization_id: organization.id
        )

      insert(:commit_author,
        commit_id: out_of_range_commit.id,
        commit: out_of_range_commit,
        github_user_id: github_user.id
      )

      in_range_commit =
        insert(:commit,
          authored_at: ~U[2023-12-25 12:00:00Z],
          repository_id: repo.id,
          organization_id: organization.id
        )

      insert(:commit_author,
        commit_id: in_range_commit.id,
        commit: in_range_commit,
        github_user_id: github_user.id
      )

      other_in_range_commit =
        insert(:commit,
          authored_at: ~U[2023-12-25 12:00:00Z],
          repository_id: repo.id,
          organization_id: organization.id
        )

      insert(:commit_author,
        commit_id: other_in_range_commit.id,
        commit: other_in_range_commit,
        github_user_id: github_user.id
      )

      opts = [
        timezone: "America/Chicago",
        start_date: ~D[2023-12-20],
        end_date: ~D[2023-12-30]
      ]

      assert {1.0, 2.0} = Portal.commits(organization.id, github_user.username, opts)
    end
  end
end
