defmodule Devhub.Users.Actions.UpsertUser do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Repo
  alias Devhub.Users.User

  @callback upsert_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def upsert_user(params) do
    params
    |> User.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:email, :picture]},
      conflict_target: [:provider, :external_id],
      returning: true
    )
  end
end
