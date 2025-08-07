defmodule Devhub.Integrations.AI.Actions.ConversationTitle do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations
  alias Devhub.Integrations.AI.Anthropic
  alias Devhub.Integrations.AI.Google
  alias Devhub.Users.Schemas.Organization

  @callback conversation_title(Organization.t(), String.t()) :: {:ok, String.t()} | {:error, :not_configured}
  def conversation_title(organization, question) do
    {:ok, integration} = Integrations.get_by(organization_id: organization.id, provider: :ai)

    if is_nil(integration.access_token) do
      {:error, :not_configured}
    else
      case integration.settings["general_model"] do
        "claude" <> _rest ->
          Anthropic.conversation_title(integration, question)

        "gemini" <> _rest ->
          Google.conversation_title(integration, question)
      end
    end
  end
end
