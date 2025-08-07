defmodule Devhub.Integrations.GitHub.Utils.UpsertPullRequest do
  @moduledoc false

  alias Devhub.Integrations.GitHub.PullRequest
  alias Devhub.Repo

  require Logger

  @callback upsert_pull_request(map()) :: {:ok, PullRequest.t()} | {:error, Ecto.Changeset.t()}
  def upsert_pull_request(attrs) do
    # we only want to replace these fields if they are passed
    replace =
      attrs
      |> Map.take([
        :title,
        :state,
        :additions,
        :deletions,
        :changed_files,
        :comments_count,
        :author,
        :is_draft,
        :first_commit_authored_at,
        :merged_at
      ])
      |> Map.keys()

    %PullRequest{}
    |> PullRequest.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, replace},
      conflict_target: [:repository_id, :number],
      returning: true
    )
  end
end
