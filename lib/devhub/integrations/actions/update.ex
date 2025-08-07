defmodule Devhub.Integrations.Actions.Update do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback update(Integration.t(), map()) :: {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def update(integration, params) do
    integration
    |> Integration.changeset(params)
    |> Repo.update()
  end
end
