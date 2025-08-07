defmodule Devhub.ApiKeys.Actions.Update do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.ApiKeys.Schemas.ApiKey
  alias Devhub.Repo

  @callback update(ApiKey.t(), String.t(), [String.t()]) :: {:ok, ApiKey.t()} | {:error, Ecto.Changeset.t()}
  def update(api_key, name, permissions) do
    api_key
    |> ApiKey.update_changeset(%{name: name, permissions: permissions})
    |> Repo.update()
  end
end
