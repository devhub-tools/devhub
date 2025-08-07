defmodule Devhub.Portal.Actions.PRCounts do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Repo

  @callback pr_counts(String.t(), String.t(), Keyword.t()) :: PullRequest.t() | nil
  def pr_counts(organization_id, author, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    query =
      from pr in PullRequest,
        join: repo in assoc(pr, :repository),
        where: repo.organization_id == ^organization_id,
        where: repo.enabled,
        where: pr.author == ^author,
        where: pr.opened_at >= ^start_date,
        where: pr.opened_at <= ^end_date,
        where: pr.state in ["CLOSED", "MERGED"],
        select: %{
          count: count(1),
          closed_prs: fragment("count(*) FILTER (WHERE merged_at IS NULL)"),
          merged_prs: fragment("count(*) FILTER (WHERE merged_at IS NOT NULL)")
        }

    Repo.one(query)
  end
end
