defmodule Devhub.Integrations.Actions.GetPullRequests do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Repo

  @callback get_pull_requests(Keyword.t(), Keyword.t()) :: [PullRequest.t()]
  def get_pull_requests(filter, opts) do
    # TODO: this will need to be refactored when we have more than one integration
    query =
      from pr in PullRequest,
        join: gu in assoc(pr, :github_user),
        join: r in assoc(pr, :repository),
        order_by: [desc: pr.updated_at],
        limit: ^(opts[:limit] || 10),
        preload: [repository: r]

    query
    |> filter(filter)
    |> Repo.all()
  end

  defp filter(query, filter) do
    Enum.reduce(filter, query, fn {key, value}, query ->
      do_filter({key, value}, query)
    end)
  end

  defp do_filter({:github_user_id, github_user_id}, query) do
    where(query, [_pr, gu], gu.id == ^github_user_id)
  end

  defp do_filter({field, value}, query) do
    where(query, [pr], field(pr, ^field) == ^value)
  end
end
