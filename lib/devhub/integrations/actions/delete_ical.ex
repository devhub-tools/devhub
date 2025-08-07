defmodule Devhub.Integrations.Actions.DeleteIcal do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Repo

  @callback delete_ical(Ical.t()) :: {:ok, Ical.t()} | {:error, Ecto.Changeset.t()}
  def delete_ical(integration) do
    Repo.delete(integration)
  end
end
