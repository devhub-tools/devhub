defmodule Devhub.Integrations.GitHub.Jobs.SyncCommit do
  @moduledoc false
  use Oban.Worker, queue: :github, priority: 8

  import Ecto.Query

  alias Devhub.Integrations
  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.Commit
  alias Devhub.Integrations.GitHub.CommitFile
  alias Devhub.Repo

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"commit_id" => commit_id}}) do
    with {:ok, commit} <- get_commit(commit_id),
         # commits are immutable so if there are already files for this commit, we don't need to re-import them
         false <- has_files?(commit),
         {:ok, repository} <- GitHub.get_repository(id: commit.repository_id),
         {:ok, integration} <- Integrations.get_by(organization_id: repository.organization_id, provider: :github),
         {:ok, %{body: %{"files" => files}}} <- Client.commit(integration, repository, commit.sha) do
      # make sure we don't slam github with requests, github requests at least 1 second between requests
      if !Devhub.test?(), do: :timer.sleep(1000)

      placeholders = %{now: DateTime.utc_now(), commit_id: commit.id, organization_id: commit.organization_id}

      commit_files =
        Enum.map(files, fn file ->
          extension =
            case Path.extname(file["filename"]) do
              "" -> Path.basename(file["filename"])
              ext -> ext
            end

          %{
            id: UXID.generate!(prefix: "cmf"),
            organization_id: {:placeholder, :organization_id},
            commit_id: {:placeholder, :commit_id},
            filename: file["filename"],
            extension: extension,
            additions: file["additions"],
            deletions: file["deletions"],
            patch: file["patch"],
            status: file["status"],
            inserted_at: {:placeholder, :now},
            updated_at: {:placeholder, :now}
          }
        end)

      {changed, nil} =
        Repo.insert_all(CommitFile, commit_files,
          placeholders: placeholders,
          on_conflict: :nothing,
          conflict_target: [:commit_id, :filename]
        )

      Logger.info("Imported #{changed} files for commit #{commit.sha}")
    end

    :ok
  end

  defp get_commit(commit_id) do
    case Repo.get(Commit, commit_id) do
      %Commit{} = commit -> {:ok, commit}
      nil -> {:error, :commit_not_found}
    end
  end

  defp has_files?(commit) do
    query = from cf in CommitFile, where: cf.commit_id == ^commit.id
    Repo.exists?(query)
  end
end
