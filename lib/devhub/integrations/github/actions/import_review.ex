defmodule Devhub.Integrations.GitHub.Actions.ImportReview do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub.PullRequestReview
  alias Devhub.Repo

  @callback import_review(map()) :: {:ok, PullRequestReview.t()} | {:error, Ecto.Changeset.t()}
  def import_review(attrs) do
    %PullRequestReview{}
    |> PullRequestReview.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:pull_request_id, :github_id])
  end
end
