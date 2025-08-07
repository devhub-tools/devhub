defmodule Devhub.Integrations.GitHub.Actions.GetInstallation do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub.Client

  @callback get_installation(String.t(), String.t()) :: {:ok, map()}
  def get_installation(organization_id, installation_id) do
    case Client.get_installation(organization_id, installation_id) do
      {:ok, %{body: body}} ->
        {:ok, body}

      _error ->
        {:error, :installation_not_found}
    end
  end
end
