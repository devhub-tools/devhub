defmodule Devhub.Coverbot.Actions.GetCoverage do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Coverbot.Coverage
  alias Devhub.Repo

  @callback get_coverage(Keyword.t()) :: {:ok, Coverage.t()} | {:error, :coverage_not_found}
  def get_coverage(by) do
    case Repo.get_by(Coverage, by) do
      %Coverage{} = coverage -> {:ok, Repo.preload(coverage, :repository)}
      nil -> {:error, :coverage_not_found}
    end
  end
end
