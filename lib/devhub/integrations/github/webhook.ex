defmodule Devhub.Integrations.GitHub.Webhook do
  @moduledoc false
  import Devhub.Integrations.GitHub.Utils.UpsertPullRequest
  import Ecto.Query

  alias Devhub.Integrations.GitHub
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo
  alias Devhub.TerraDesk

  def handle(app, payload) do
    with {:ok, event} <- Jason.decode(payload),
         :ok <- TerraDesk.handle_webhook(app, event),
         :ok <- handle_for_metrics(event) do
      :ok
    else
      error ->
        raise "Failed to handle webhook event: #{inspect(error)}"
    end
  end

  defp handle_for_metrics(%{"installation" => %{"id" => installation_id}} = event) do
    installation_id
    |> get_integrations()
    |> Enum.each(fn integration ->
      repository = handle_repository(event, integration)
      pull_request = handle_pull_request(event, integration, repository)
      handle_review(event, pull_request)
      handle_commits(event, repository)
    end)

    :ok
  end

  defp handle_repository(%{"repository" => repository}, integration) do
    {:ok, repository} =
      GitHub.upsert_repository(%{
        name: repository["name"],
        owner: repository["owner"]["login"],
        organization_id: integration.organization.id,
        default_branch: repository["default_branch"],
        pushed_at: handle_timestamp(repository["pushed_at"])
      })

    repository
  end

  defp handle_repository(_integration, _event), do: nil

  defp handle_pull_request(%{"action" => "synchronize", "pull_request" => pull_request}, integration, repository) do
    %{
      "commits" => %{"nodes" => commits},
      "reviews" => %{"nodes" => reviews},
      "timelineItems" => %{"nodes" => timeline_items}
    } = GitHub.pull_request_details(integration, repository, pull_request["number"])

    opened_at =
      case timeline_items do
        [node] -> node["createdAt"]
        _no_events -> pull_request["createdAt"]
      end

    first_commit_authored_at =
      case commits do
        [first_commit] -> first_commit["commit"]["authoredDate"]
        [] -> nil
      end

    {:ok, pull_request} =
      upsert_pull_request(%{
        organization_id: integration.organization_id,
        repository_id: repository.id,
        additions: pull_request["additions"],
        author: pull_request["user"]["login"],
        changed_files: pull_request["changed_files"],
        comments_count: pull_request["comments"] + pull_request["review_comments"],
        deletions: pull_request["deletions"],
        first_commit_authored_at: first_commit_authored_at,
        merged_at: pull_request["merged_at"],
        is_draft: pull_request["draft"],
        number: pull_request["number"],
        opened_at: (!pull_request["draft"] && opened_at) || nil,
        state: String.upcase(pull_request["state"]),
        title: pull_request["title"]
      })

    Enum.each(reviews, fn review ->
      GitHub.import_review(%{
        organization_id: pull_request.organization_id,
        pull_request_id: pull_request.id,
        github_id: review["id"],
        author: review["author"]["login"],
        reviewed_at: review["createdAt"]
      })
    end)

    pull_request
  end

  defp handle_pull_request(%{"pull_request" => pull_request}, _integration, repository) do
    {:ok, pull_request} =
      upsert_pull_request(%{
        organization_id: repository.organization_id,
        number: pull_request["number"],
        title: pull_request["title"],
        repository_id: repository.id,
        state: String.upcase(pull_request["state"]),
        author: pull_request["user"]["login"],
        is_draft: pull_request["draft"],
        merged_at: pull_request["merged_at"]
      })

    pull_request
  end

  defp handle_pull_request(_event, _integration, _repository), do: nil

  defp handle_commits(%{"commits" => commits}, repository) do
    Enum.each(commits, fn commit_details ->
      GitHub.import_commit(
        %{
          organization_id: repository.organization_id,
          sha: commit_details["id"],
          message: commit_details["message"],
          authored_at: commit_details["timestamp"],
          repository_id: repository.id
        },
        commit_details["author"]["username"]
      )
    end)
  end

  defp handle_commits(_event, _repository), do: :ok

  defp handle_review(%{"review" => review}, pull_request) do
    GitHub.import_review(%{
      organization_id: pull_request.organization_id,
      pull_request_id: pull_request.id,
      github_id: review["node_id"],
      author: review["user"]["login"],
      reviewed_at: review["submitted_at"]
    })
  end

  defp handle_review(_event, _pull_request), do: :ok

  defp handle_timestamp(timestamp) when is_integer(timestamp) do
    DateTime.from_unix!(timestamp)
  end

  defp handle_timestamp(timestamp) when is_binary(timestamp) do
    timestamp
  end

  defp get_integrations(installation_id) do
    query =
      from i in Integration,
        where: i.provider == :github,
        where: i.external_id == ^to_string(installation_id),
        join: o in assoc(i, :organization),
        preload: [organization: o]

    Repo.all(query)
  end
end
