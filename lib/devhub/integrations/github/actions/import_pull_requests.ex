defmodule Devhub.Integrations.GitHub.Actions.ImportPullRequests do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.GitHub.Actions.ImportCommit
  import Devhub.Integrations.GitHub.Actions.ImportReview
  import Devhub.Integrations.GitHub.Utils.HasNextPage
  import Devhub.Integrations.GitHub.Utils.UpsertPullRequest

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_pull_requests(Integration.t(), Repository.t(), Keyword.t()) :: :ok
  def import_pull_requests(integration, repository, opts) do
    cursor = Keyword.get(opts, :cursor, nil)
    since = Keyword.get(opts, :since, nil)

    Logger.info("Importing pull requests for #{repository.id} at cursor #{cursor}")

    %{
      data: pull_requests,
      has_next_page: has_next_page,
      end_cursor: end_cursor
    } = fetch_pull_requests(integration, repository, cursor)

    pull_requests
    |> Enum.reject(&is_nil(&1["author"]))
    |> Enum.each(fn pull_request ->
      import_pull_request(pull_request, repository, integration)
    end)

    has_next_page = has_next_page?(has_next_page, since, List.last(pull_requests)["updatedAt"])

    if has_next_page do
      # github requests 1 second between requests
      if !Devhub.test?(), do: :timer.sleep(1000)
      opts = Keyword.put(opts, :cursor, end_cursor)
      import_pull_requests(integration, repository, opts)
    end

    :ok
  end

  defp import_pull_request(
         %{"commits" => %{"nodes" => commits}, "reviews" => %{"nodes" => reviews}} = pull_request,
         repository,
         integration
       ) do
    first_commit_authored_at = List.first(commits)["commit"]["authoredDate"]

    opened_at =
      case pull_request["timelineItems"]["nodes"] do
        [node] -> node["createdAt"]
        _no_events -> pull_request["createdAt"]
      end

    {:ok, pull_request} =
      upsert_pull_request(%{
        organization_id: repository.organization_id,
        number: pull_request["number"],
        title: pull_request["title"],
        repository_id: repository.id,
        state: pull_request["state"],
        additions: pull_request["additions"],
        deletions: pull_request["deletions"],
        changed_files: pull_request["changedFiles"],
        comments_count: pull_request["totalCommentsCount"],
        author: pull_request["author"]["login"],
        is_draft: pull_request["isDraft"],
        first_commit_authored_at: first_commit_authored_at,
        opened_at: opened_at,
        merged_at: pull_request["mergedAt"]
      })

    Enum.each(commits, fn %{"commit" => commit} ->
      import_commit(
        %{
          organization_id: repository.organization_id,
          sha: commit["oid"],
          message: commit["message"],
          authored_at: commit["authoredDate"],
          repository_id: repository.id,
          additions: commit["additions"],
          deletions: commit["deletions"]
        },
        commit["author"]["user"]["login"]
      )
    end)

    ignore_usernames = integration.settings["ignore_usernames"] || []

    reviews
    |> Enum.reject(&(&1["author"]["login"] in ignore_usernames))
    |> Enum.each(fn review ->
      import_review(%{
        organization_id: pull_request.organization_id,
        pull_request_id: pull_request.id,
        github_id: review["id"],
        author: review["author"]["login"],
        reviewed_at: review["createdAt"]
      })
    end)
  end

  defp fetch_pull_requests(integration, repository, cursor) do
    query = """
    query PullRequests($name: String!, $owner: String!, $branch: String!, $cursor: String) {
      repository(name: $name, owner: $owner) {
        pullRequests(
          baseRefName: $branch
          orderBy: { direction: DESC, field: UPDATED_AT }
          first: 10
          after: $cursor
        ) {
          nodes {
            additions
            changedFiles
            createdAt
            deletions
            mergedAt
            isDraft
            number
            state
            title
            totalCommentsCount
            updatedAt

            author {
              login
            }

            commits(first: 100) {
              nodes {
                commit {
                  oid
                  message
                  authoredDate
                  additions
                  deletions

                  author {
                    user {
                      login
                    }
                  }
                }
              }
            }

            timelineItems(itemTypes: [READY_FOR_REVIEW_EVENT], last: 1) {
              nodes {
                ... on ReadyForReviewEvent {
                  createdAt
                }
              }
            }

            reviews (first: 100) {
              nodes {
                id
                createdAt
                author {
                  login
                }
              }
            }
          }

          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
    """

    {:ok,
     %{
       body: %{
         "data" => %{
           "repository" => %{
             "pullRequests" => %{
               "nodes" => pull_requests,
               "pageInfo" => %{
                 "hasNextPage" => has_next_page,
                 "endCursor" => end_cursor
               }
             }
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{
        name: repository.name,
        owner: repository.owner,
        branch: repository.default_branch,
        cursor: cursor
      })

    %{
      data: pull_requests,
      has_next_page: has_next_page,
      end_cursor: end_cursor
    }
  end
end
