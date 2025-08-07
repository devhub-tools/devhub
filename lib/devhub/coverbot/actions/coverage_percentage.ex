defmodule Devhub.Coverbot.Actions.CoveragePercentage do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Coverbot.Actions.GetLatestCoverage
  alias Devhub.Coverbot.Coverage
  alias Devhub.Integrations.GitHub.Repository

  @callback coverage_percentage(Repository.t(), String.t()) ::
              {:ok, Decimal.t()} | {:error, :coverage_not_found}
  def coverage_percentage(repository, branch) do
    case GetLatestCoverage.get_latest_coverage(repository, branch) do
      {:ok, %Coverage{percentage: percentage}} -> {:ok, percentage}
      error -> error
    end
  end
end
