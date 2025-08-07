defmodule Devhub.Integrations.Linear.Actions.UpsertUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.Linear.User
  alias Devhub.Repo

  @callback upsert_user(map()) :: {:ok, User.t()} | {:error, Changeset.t()}
  def upsert_user(params) do
    params
    |> User.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:name]},
      conflict_target: [:organization_id, :external_id],
      returning: true
    )
  end
end
