defmodule Devhub.Integrations.Linear.Actions.ImportUsers do
  @moduledoc false
  @behaviour __MODULE__

  import Devhub.Integrations.Linear.Actions.UpsertUser

  alias Devhub.Integrations.Linear.Client
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @callback import_users(Integration.t()) :: :ok
  def import_users(integration, cursor \\ nil) do
    Logger.info("Importing users for cursor: #{cursor}")

    query = """
    query ImportUsers($cursor: String) {
      users(
        first: 50
        after: $cursor
      ) {
        nodes {
          id
          name
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
           "users" => %{"nodes" => users, "pageInfo" => %{"hasNextPage" => has_next_page, "endCursor" => end_cursor}}
         }
       }
     }} = Client.graphql(integration, query, %{cursor: cursor})

    Enum.each(users, fn user ->
      upsert_user(%{
        organization_id: integration.organization_id,
        external_id: user["id"],
        name: user["name"]
      })
    end)

    if has_next_page do
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_users(integration, end_cursor)
    end

    :ok
  end
end
