defmodule Devhub.Integrations.GitHub.Actions.ImportDefaultBranch do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.GitHub.Actions.ImportCommit

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_default_branch(Integration.t(), Repository.t(), Keyword.t()) :: :ok
  def import_default_branch(integration, repository, opts) do
    cursor = Keyword.get(opts, :cursor, nil)

    Logger.info("Importing default branch for #{repository.id} at cursor #{cursor}")

    %{
      data: commits,
      has_next_page: has_next_page,
      end_cursor: end_cursor
    } = fetch_commits(integration, repository, opts)

    Enum.each(commits, fn commit ->
      import_commit(
        %{
          organization_id: repository.organization_id,
          sha: commit["oid"],
          message: commit["message"],
          authored_at: commit["authoredDate"],
          repository_id: repository.id,
          additions: commit["additions"],
          deletions: commit["deletions"],
          on_default_branch: true
        },
        commit["author"]["user"]["login"]
      )
    end)

    if has_next_page do
      # github requests 1 second between requests
      if !Devhub.test?(), do: :timer.sleep(1000)
      opts = Keyword.put(opts, :cursor, end_cursor)
      import_default_branch(integration, repository, opts)
    end

    :ok
  end

  defp fetch_commits(integration, repository, opts) do
    cursor = Keyword.get(opts, :cursor, nil)
    since = opts[:since] && "#{Date.to_iso8601(opts[:since])}T00:00:00Z"

    query = """
    query GetDefaultBranchCommits($name: String!, $owner: String!, $cursor: String, $since: GitTimestamp) {
      repository(name: $name, owner: $owner) {
        defaultBranchRef {
          target {
            ... on Commit {
              history(first: 100, after: $cursor, since: $since) {
                nodes {
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

                pageInfo {
                  hasNextPage
                  endCursor
                }
              }
            }
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
             "defaultBranchRef" => %{
               "target" => %{
                 "history" => %{
                   "nodes" => commits,
                   "pageInfo" => %{
                     "hasNextPage" => has_next_page,
                     "endCursor" => end_cursor
                   }
                 }
               }
             }
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{
        name: repository.name,
        owner: repository.owner,
        since: since,
        cursor: cursor
      })

    %{
      data: commits,
      has_next_page: has_next_page,
      end_cursor: end_cursor
    }
  end
end
