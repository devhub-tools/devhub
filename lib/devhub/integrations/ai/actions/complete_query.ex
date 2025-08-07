defmodule Devhub.Integrations.AI.Actions.CompleteQuery do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations
  alias Devhub.Integrations.AI.Anthropic
  alias Devhub.Integrations.AI.Google
  alias Devhub.QueryDesk
  alias Devhub.QueryDesk.Databases.Adapter
  alias Devhub.Users.Schemas.OrganizationUser

  @callback complete_query(
              organization_user :: OrganizationUser.t(),
              database_id :: String.t(),
              prefix :: String.t(),
              suffix :: String.t()
            ) :: {:ok, String.t()} | {:error, String.t()}
  def complete_query(organization_user, database_id, prefix, suffix) do
    {:ok, database} =
      QueryDesk.get_database(id: database_id, organization_id: organization_user.organization_id)

    schema = Adapter.get_schema(database, organization_user.user_id)
    {:ok, integration} = Integrations.get_by(organization_id: organization_user.organization_id, provider: :ai)

    if is_nil(integration.access_token) do
      {:error, :not_configured}
    else
      case integration.settings["query_model"] do
        "claude" <> _rest ->
          Anthropic.complete_query(integration, schema, prefix, suffix)

        "gemini" <> _rest ->
          Google.complete_query(integration, schema, prefix, suffix)
      end
    end
  end
end
