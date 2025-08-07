defmodule Devhub.Coverbot.Actions.GetLatestCoverage do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Coverbot.Coverage
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Repo

  @callback get_latest_coverage(Repository.t(), String.t()) ::
              {:ok, Coverage.t()} | {:error, :coverage_not_found}
  def get_latest_coverage(repository, branch) do
    query =
      from c in Coverage,
        where: c.repository_id == ^repository.id,
        where: c.ref == ^"refs/heads/#{branch}",
        order_by: [desc: c.updated_at],
        limit: 1

    case Repo.one(query) do
      %Coverage{} = coverage -> {:ok, coverage}
      nil -> {:error, :coverage_not_found}
    end
  end
end
