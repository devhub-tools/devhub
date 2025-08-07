defmodule Devhub.Shared.Actions.InsertOrUpdateLabel do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Shared.Schemas.Label

  @callback insert_or_update_label(Label.t(), map()) :: {:ok, Label.t()} | {:error, Ecto.Changeset.t()}
  def insert_or_update_label(label, params) do
    label
    |> Label.changeset(params)
    |> Repo.insert_or_update(
      on_conflict: {:replace, [:name]},
      conflict_target: [:organization_id, :name],
      returning: true
    )
  end
end
