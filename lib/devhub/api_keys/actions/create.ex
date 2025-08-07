defmodule Devhub.ApiKeys.Actions.Create do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.ApiKeys.Schemas.ApiKey
  alias Devhub.Repo
  alias Devhub.Users.Schemas.Organization

  @doc """
  Generates an api key and stores it in the database.

  ## Examples

      iex> create()
      {:ok, "6HKCrhhl7cjDkaxT60xZ8k7Mg6mfh_VJi-NxFK_Z64wgrWrCE2JB5dHFraTKIXD9ojn5VOUhHJ4iSyJyaVBUgA"}

  """
  @callback create(Organization.t(), String.t(), [atom()]) ::
              {:ok, ApiKey.t(), String.t()} | {:error, String.t()}
  def create(organization, name, permissions) do
    <<selector::binary-size(16), verifier::binary-size(16)>> =
      token = :crypto.strong_rand_bytes(32)

    %{
      organization_id: organization.id,
      name: name,
      permissions: permissions,
      selector: selector,
      verify_hash: :crypto.hash(:sha256, verifier)
    }
    |> ApiKey.create_changeset()
    |> Repo.insert()
    |> case do
      {:ok, api_key} ->
        {:ok, api_key, "dh_" <> Devhub.Utils.Base58.encode(organization.id <> ":" <> token)}

      _error ->
        {:error, "Failed to create api key"}
    end
  end
end
