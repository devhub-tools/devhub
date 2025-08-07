defmodule Devhub.Integrations.Actions.InsertOrUpdate do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback insert_or_update(Integration.t(), map()) :: {:ok, Integration.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update(integration, attrs) do
    integration
    |> Integration.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
