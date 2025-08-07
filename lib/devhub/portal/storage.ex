defmodule Devhub.Metrics.Storage do
  @moduledoc false
  import Ecto.Query

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Integrations.GitHub.User, as: GitHubUser
  alias Devhub.Integrations.Linear.Team, as: LinearTeam
  alias Devhub.Integrations.Linear.User, as: LinearUser

  def merged_prs_core_query(organization_id, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    from pr in PullRequest,
      join: repo in assoc(pr, :repository),
      join: gu in assoc(pr, :github_user),
      as: :github_user,
      where: repo.organization_id == ^organization_id,
      where: repo.enabled,
      where: not is_nil(pr.merged_at),
      where: pr.merged_at >= ^start_date,
      where: pr.merged_at <= ^end_date
  end

  def maybe_filter_team_through_linear(query, nil), do: query

  def maybe_filter_team_through_linear(query, team_id) do
    from t in query,
      join: lt in LinearTeam,
      on: t.linear_team_id == lt.id,
      where: lt.team_id == ^team_id
  end

  def maybe_filter_team_through_commit_author(query, nil), do: query

  def maybe_filter_team_through_commit_author(query, team_id) do
    from [github_user: gu] in query,
      join: ou in assoc(gu, :organization_user),
      join: m in assoc(ou, :team_members),
      where: m.team_id == ^team_id
  end

  def maybe_filter_team_through_github_user(query, nil), do: query

  def maybe_filter_team_through_github_user(query, team_id) do
    from t in query,
      join: gu in GitHubUser,
      on: gu.username == t.author,
      join: ou in assoc(gu, :organization_user),
      join: m in assoc(ou, :team_members),
      where: m.team_id == ^team_id
  end

  def maybe_filter_team_through_linear_user(query, nil), do: query

  def maybe_filter_team_through_linear_user(query, team_id) do
    from t in query,
      join: lu in LinearUser,
      on: t.linear_user_id == lu.id,
      join: ou in assoc(lu, :organization_user),
      join: m in assoc(ou, :team_members),
      where: m.team_id == ^team_id
  end

  def maybe_filter_dev(query, nil), do: query

  def maybe_filter_dev(query, dev) do
    from t in query, where: t.author == ^dev
  end
end
