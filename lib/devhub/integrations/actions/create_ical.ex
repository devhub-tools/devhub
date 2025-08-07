defmodule Devhub.Integrations.Actions.CreateIcal do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Schemas.Ical
  alias Devhub.Repo

  @callback create_ical(map()) :: {:ok, Ical.t()} | {:error, Ecto.Changeset.t()}
  def create_ical(params) do
    params
    |> Ical.changeset()
    |> Repo.insert()
  end
end
