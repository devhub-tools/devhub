defmodule Devhub.ApiKeys.Actions.Revoke do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.ApiKeys.Schemas.ApiKey
  alias Devhub.Repo

  @callback revoke(%ApiKey{} | String.t()) :: {:ok, %ApiKey{}} | {:error, :api_key_not_found}
  def revoke(api_key_id) when is_binary(api_key_id) do
    case Repo.get(ApiKey, api_key_id) do
      %ApiKey{} = api_key -> revoke(api_key)
      _error -> {:error, :api_key_not_found}
    end
  end

  def revoke(api_key) do
    api_key
    |> ApiKey.update_changeset(%{expires_at: DateTime.utc_now()})
    |> Repo.update()
  end
end
