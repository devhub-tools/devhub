defmodule Devhub.Integrations.GitHub.Actions.ImportCommit do
  @moduledoc false
  @behaviour __MODULE__

  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Integrations.GitHub.CommitAuthor
  alias Devhub.Integrations.GitHub.Jobs.SyncCommit
  alias Devhub.Integrations.GitHub.User
  alias Devhub.Repo

  @callback import_commit(map(), String.t()) :: Commit.t()
  def import_commit(attrs, author) do
    replace_keys = attrs |> Map.take([:message, :additions, :deletions, :on_default_branch]) |> Map.keys()

    commit =
      %Commit{}
      |> Commit.changeset(attrs)
      |> Repo.insert!(
        on_conflict: {:replace, [:updated_at | replace_keys]},
        conflict_target: [:repository_id, :sha],
        returning: true
      )

    %{commit_id: commit.id} |> SyncCommit.new() |> Oban.insert!()

    if author do
      github_user =
        %User{}
        |> User.changeset(%{
          organization_id: attrs.organization_id,
          username: author
        })
        |> Repo.insert!(
          on_conflict: {:replace, [:username]},
          conflict_target: [:organization_id, :username],
          returning: true
        )

      %CommitAuthor{}
      |> CommitAuthor.changeset(%{github_user_id: github_user.id, commit_id: commit.id})
      |> Repo.insert!(on_conflict: :nothing, conflict_target: [:commit_id, :github_user_id])
    end

    commit
  end
end
