defmodule Devhub.Integrations.Actions.UpdateIcal do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Repo

  @callback update_ical(Ical.t(), map()) :: {:ok, Ical.t()} | {:error, Ecto.Changeset.t()}
  def update_ical(integration, params) do
    integration
    |> Ical.changeset(params)
    |> Repo.update()
  end
end
