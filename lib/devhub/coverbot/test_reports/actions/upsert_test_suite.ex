defmodule Devhub.Coverbot.TestReports.Actions.UpsertTestSuite do
  @moduledoc false

  @behaviour __MODULE__

  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Repo

  @callback upsert_test_suite(map()) ::
              {:ok, TestSuite.t()} | {:error, Ecto.Changeset.t()}
  def upsert_test_suite(params) do
    params
    |> TestSuite.changeset()
    |> Repo.insert(
      on_conflict: {:replace, [:name]},
      conflict_target: [:name, :organization_id, :repository_id],
      returning: true
    )
  end
end
