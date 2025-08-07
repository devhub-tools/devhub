defmodule Devhub.ApiKeys.Actions.Verify do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.ApiKeys.Schemas.ApiKey
  alias Devhub.Repo

  @doc """
  Gets a single api key. Must Base.decode64 the api key before passing to this function.

  ## Examples

      iex> get(<<19, 127, 52, 56, 117, 12, 199, 70, ...>>)
      {:ok, %ApiKey{}}

      iex> get("123")
      {:error, :invalid_api_key}

  """
  @callback verify(String.t()) :: {:ok, ApiKey.t()} | {:error, :invalid_api_key}
  def verify("dh_" <> token) do
    query =
      fn organization_id, selector ->
        from s in ApiKey,
          where: s.organization_id == ^organization_id,
          where: s.selector == ^selector,
          where: is_nil(s.expires_at) or s.expires_at > ^DateTime.utc_now(),
          preload: :organization
      end

    with {:ok, decoded_token} <- Devhub.Utils.Base58.decode(token),
         [organization_id, token] <- String.split(decoded_token, ":", parts: 2),
         <<selector::binary-size(16), verifier::binary-size(16)>> <- token,
         %{verify_hash: verify_hash} = api_key <- organization_id |> query.(selector) |> Repo.one(),
         true <- Plug.Crypto.secure_compare(verify_hash, :crypto.hash(:sha256, verifier)) do
      {:ok, api_key}
    else
      _error ->
        {:error, :invalid_api_key}
    end
  end

  def verify(_token), do: {:error, :invalid_api_key}
end
