defmodule Devhub.Integrations.Actions.Create do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback create(map()) :: {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    params
    |> Integration.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:external_id, :access_token]},
      conflict_target: [:organization_id, :provider]
    )
  end
end
