defmodule Devhub.Integrations.Linear.Actions.ImportIssues do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.Linear.Actions.UpsertIssue

  alias Devhub.Integrations.Linear.Client
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_issues(Integration.t(), String.t()) :: :ok
  def import_issues(integration, since \\ "-P1D", cursor \\ nil) do
    Logger.info("Importing issues for cursor: #{cursor}")

    query = """
    query ImportIssues($since: DateTimeOrDuration!, $cursor: String) {
      issues(
        first: 50,
        orderBy: updatedAt,
        filter: {
          updatedAt: { gte: $since }
        }
        after: $cursor
      ) {
        nodes {
          archivedAt
          canceledAt
          completedAt
          createdAt
          estimate
          id
          identifier
          priority
          priorityLabel
          startedAt
          title
          url

          state {
            id
            color
            name
            type
          }

          labels {
            nodes {
              id
            }
          }

          assignee {
            id
            name
          }

          team {
            id
            key
            name
          }
        }

        pageInfo {
          endCursor
          hasNextPage
        }
      }
    }
    """

    {:ok,
     %{
       body: %{
         "data" => %{
           "issues" => %{
             "nodes" => issues,
             "pageInfo" => %{
               "hasNextPage" => has_next_page,
               "endCursor" => end_cursor
             }
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{since: since, cursor: cursor})

    Enum.each(issues, fn issue ->
      upsert_issue(integration, issue)
    end)

    if has_next_page do
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_issues(integration, since, end_cursor)
    end

    :ok
  end
end
