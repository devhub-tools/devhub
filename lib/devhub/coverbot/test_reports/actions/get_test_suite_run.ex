defmodule Devhub.Coverbot.TestReports.Actions.GetTestSuiteRun do
  @moduledoc false

  @behaviour __MODULE__

  alias Devhub.Coverbot.TestReports.Schemas.TestSuiteRun
  alias Devhub.Repo

  @callback get_test_suite_run(Keyword.t()) :: {:ok, TestSuiteRun} | {:error, :test_suite_run_not_found}
  def get_test_suite_run(by) do
    case(Repo.get_by(TestSuiteRun, by)) do
      %TestSuiteRun{} = test_suite_run -> {:ok, test_suite_run}
      nil -> {:error, :test_suite_run_not_found}
    end
  end
end
