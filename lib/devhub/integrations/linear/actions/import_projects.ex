defmodule Devhub.Integrations.Linear.Actions.ImportProjects do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.Linear.Actions.UpsertProject

  alias Devhub.Integrations.Linear.Client
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_projects(Integration.t(), String.t()) :: :ok
  def import_projects(integration, since \\ "-P1D", cursor \\ nil) do
    Logger.info("Importing projects for cursor: #{cursor}")

    query = """
    query ImportProjects($since: DateTimeOrDuration!, $cursor: String) {
      projects(
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
          id
          name
          status { name }
        }

        pageInfo { endCursor hasNextPage }
      }
    }
    """

    {:ok,
     %{
       body: %{
         "data" => %{
           "projects" => %{
             "nodes" => projects,
             "pageInfo" => %{
               "hasNextPage" => has_next_page,
               "endCursor" => end_cursor
             }
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{since: since, cursor: cursor})

    Enum.each(projects, fn project ->
      upsert_project(integration, project)
    end)

    if has_next_page do
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_projects(integration, since, end_cursor)
    end

    :ok
  end
end
