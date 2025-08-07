defmodule Devhub.Integrations.GitHub.Actions.UpsertRepository do
  @moduledoc false

  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Repo

  require Logger

  @callback upsert_repository(map()) :: {:ok, Repository.t()} | {:error, Ecto.Changeset.t()}
  def upsert_repository(attrs) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:pushed_at, :archived]},
      conflict_target: [:organization_id, :name, :owner],
      returning: true
    )
  end
end
