defmodule Devhub.Portal.Actions.ReviewedPRs do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequestReview
  alias Devhub.Repo

  @callback reviewed_prs(String.t(), String.t(), Keyword.t()) ::
              %{prs_reviewed: integer(), time_to_review: integer()} | nil
  def reviewed_prs(organization_id, author, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    subquery =
      from prr in PullRequestReview,
        join: pr in assoc(prr, :pull_request),
        join: repo in assoc(pr, :repository),
        where: repo.organization_id == ^organization_id,
        where: repo.enabled,
        where: prr.author == ^author,
        where: prr.reviewed_at >= ^start_date,
        where: prr.reviewed_at <= ^end_date,
        select: %{
          pull_request_id: pr.id,
          time_to_review:
            fragment(
              "extract(epoch from min(?) - min(?))/3600",
              prr.reviewed_at,
              pr.opened_at
            )
        },
        group_by: pr.id

    query =
      from results in subquery(subquery),
        select: %{
          prs_reviewed: count(1),
          time_to_review: fragment("ROUND(AVG(?), 1)", results.time_to_review)
        }

    Repo.one(query)
  end
end
