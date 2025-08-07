defmodule Devhub.Portal.Actions.Commits do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.GitHub.CommitAuthor
  alias Devhub.Repo

  @callback commits(String.t(), String.t(), Keyword.t()) ::
              {float(), float()}
  def commits(organization_id, username, opts) do
    summary =
      organization_id
      |> commit_counts(username, opts)
      |> Enum.group_by(& &1.week)
      |> Enum.sort_by(&elem(&1, 0), {:desc, Date})
      |> Enum.map(fn {week, days} ->
        number_of_days = Enum.count(days)

        average =
          days |> Enum.map(& &1.count) |> Enum.sum() |> Kernel./(number_of_days) |> Float.round(1)

        {week, %{commits_per_day: average, number_of_days: number_of_days}}
      end)

    number_of_weeks = Enum.count(summary)

    if number_of_weeks == 0 do
      {0, 0}
    else
      coding_days_per_week =
        summary
        |> Enum.map(&elem(&1, 1).number_of_days)
        |> Enum.sum()
        |> Kernel./(number_of_weeks)
        |> Float.round(1)

      commits_per_day =
        summary
        |> Enum.map(&elem(&1, 1).commits_per_day)
        |> Enum.sum()
        |> Kernel./(number_of_weeks)
        |> Float.round(1)

      {coding_days_per_week, commits_per_day}
    end
  end

  defp commit_counts(organization_id, username, opts) do
    start_date = Timex.Timezone.convert(opts[:start_date], opts[:timezone])
    end_date = Timex.Timezone.convert(opts[:end_date], opts[:timezone])

    query =
      from ca in CommitAuthor,
        join: gu in assoc(ca, :github_user),
        join: c in assoc(ca, :commit),
        where: gu.organization_id == ^organization_id,
        where: gu.username == ^username,
        where: c.authored_at >= ^start_date,
        where: c.authored_at <= ^end_date,
        select: %{
          date:
            type(
              fragment("date_trunc('day', ? at time zone 'UTC' at time zone ?)", c.authored_at, ^opts[:timezone]),
              :date
            ),
          week:
            type(
              fragment("date_trunc('week', ? at time zone 'UTC' at time zone ?)", c.authored_at, ^opts[:timezone]),
              :date
            ),
          count: count(1)
        },
        group_by: [1, 2]

    Repo.all(query)
  end
end
