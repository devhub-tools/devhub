defmodule Devhub.Coverbot.TestReports.Actions.GetTestSuite do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Coverbot.TestReports.Schemas.TestSuite
  alias Devhub.Repo

  @callback get_test_suite(String.t()) :: {:ok, TestSuite.t()} | {:error, :test_suite_not_found}
  def get_test_suite(test_suite_id) do
    TestSuite
    |> Repo.get(test_suite_id)
    |> Repo.preload([:repository, test_suite_runs: :commit])
    |> case do
      %TestSuite{} = run -> {:ok, run}
      nil -> {:error, :test_suite_not_found}
    end
  end
end
