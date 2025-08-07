defmodule Devhub.Integrations.Linear.Actions.ImportLabels do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.Linear.Actions.UpsertLabel

  alias Devhub.Integrations.Linear.Client
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_labels(Integration.t()) :: :ok
  def import_labels(integration, cursor \\ nil) do
    Logger.info("Importing labels for cursor: #{cursor}")

    query = """
    query ImportLabels($cursor: String) {
      issueLabels(
        first: 50
        orderBy: updatedAt
        after: $cursor
      ) {
        nodes {
          id
          name
          color
          isGroup

          parent {
            id
          }

          team {
            id
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
           "issueLabels" => %{
             "nodes" => labels,
             "pageInfo" => %{"hasNextPage" => has_next_page, "endCursor" => end_cursor}
           }
         }
       }
     }} = Client.graphql(integration, query, %{cursor: cursor})

    Enum.each(labels, fn label ->
      upsert_label(integration, label)
    end)

    if has_next_page do
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_labels(integration, end_cursor)
    end

    :ok
  end
end
