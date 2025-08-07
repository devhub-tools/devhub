defmodule Devhub.Integrations.GitHub.Actions.ImportRepositories do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.GitHub.Actions.UpsertRepository

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_repositories(Integration.t()) :: :ok
  def import_repositories(integration, cursor \\ nil) do
    query = """
    query ListRepositories($login: String!, $cursor: String) {
      organization(login: $login) {
        repositories(
          first: 100
          after: $cursor
          orderBy: { direction: DESC, field: PUSHED_AT }
        ) {
          nodes {
            owner {
              login
            }
            name
            defaultBranchRef {
              name
            }
            pushedAt
            isArchived
          }
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }
    }
    """

    {:ok,
     %{
       body: %{
         "data" => %{
           "organization" => %{
             "repositories" => %{
               "nodes" => repositories,
               "pageInfo" => %{
                 "hasNextPage" => has_next_page,
                 "endCursor" => end_cursor
               }
             }
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{login: integration.settings["login"], cursor: cursor})

    Enum.each(repositories, fn repository ->
      upsert_repository(%{
        name: repository["name"],
        owner: repository["owner"]["login"],
        organization_id: integration.organization_id,
        default_branch: repository["defaultBranchRef"]["name"],
        pushed_at: repository["pushedAt"],
        archived: repository["isArchived"]
      })
    end)

    if has_next_page do
      # github requests 1 second between requests
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_repositories(integration, end_cursor)
    end

    :ok
  end
end
