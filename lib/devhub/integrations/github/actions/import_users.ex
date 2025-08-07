defmodule Devhub.Integrations.GitHub.Actions.ImportUsers do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.User
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  require Logger

  @callback import_users(Integration.t()) :: :ok
  def import_users(integration, cursor \\ nil) do
    query = """
    query ListUsers($login: String!, $cursor: String) {
      organization(login: $login) {
        membersWithRole(first: 100, after: $cursor) {
          nodes {
            login
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
             "membersWithRole" => %{
               "nodes" => users,
               "pageInfo" => %{"hasNextPage" => has_next_page, "endCursor" => end_cursor}
             }
           }
         }
       }
     }} = Client.graphql(integration, query, %{login: integration.settings["login"], cursor: cursor})

    Enum.each(users, fn %{"login" => username} ->
      import_user(integration.organization_id, username)
    end)

    if has_next_page do
      # github requests 1 second between requests
      if !Devhub.test?(), do: :timer.sleep(1000)
      import_users(integration, end_cursor)
    end

    :ok
  end

  defp import_user(organization_id, username) do
    %{
      organization_id: organization_id,
      username: username
    }
    |> User.changeset()
    |> Repo.insert!(
      on_conflict: :nothing,
      conflict_target: [:organization_id, :username]
    )
  end
end
