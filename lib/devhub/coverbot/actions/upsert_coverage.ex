defmodule Devhub.Coverbot.Actions.UpsertCoverage do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo

  @callback upsert_coverage(map()) :: {:ok, Coverage.t()} | {:error, Ecto.Changeset.t()}
  def upsert_coverage(attrs) do
    attrs
    |> Coverage.changeset()
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: [:sha, :repository_id],
      returning: true
    )
  end
end
