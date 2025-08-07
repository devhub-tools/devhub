defmodule Devhub.Integrations.GitHub do
  @moduledoc false
  @behaviour __MODULE__
  @behaviour Devhub.Integrations.GitHub.Actions.GetApp
  @behaviour Devhub.Integrations.GitHub.Actions.GetAppToken
  @behaviour Devhub.Integrations.GitHub.Actions.GetCommit
  @behaviour Devhub.Integrations.GitHub.Actions.GetInstallation
  @behaviour Devhub.Integrations.GitHub.Actions.ImportCommit
  @behaviour Devhub.Integrations.GitHub.Actions.ImportDefaultBranch
  @behaviour Devhub.Integrations.GitHub.Actions.ImportPullRequests
  @behaviour Devhub.Integrations.GitHub.Actions.ImportRepositories
  @behaviour Devhub.Integrations.GitHub.Actions.ImportReview
  @behaviour Devhub.Integrations.GitHub.Actions.ImportUsers
  @behaviour Devhub.Integrations.GitHub.Actions.RegisterApp
  @behaviour Devhub.Integrations.GitHub.Actions.SetupComplete
  @behaviour Devhub.Integrations.GitHub.Actions.UpsertRepository

  use Nebulex.Caching

  alias Devhub.Integrations.GitHub.Actions
  alias Devhub.Integrations.GitHub.Client
  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.GitHub.Storage
  alias Devhub.Integrations.Schemas.Integration

  require Logger

  @impl Actions.SetupComplete
  defdelegate setup_complete?(organization), to: Actions.SetupComplete

  @impl Actions.RegisterApp
  defdelegate register_app(organization, code), to: Actions.RegisterApp

  @impl Actions.GetApp
  defdelegate get_app(by), to: Actions.GetApp

  @impl Actions.GetAppToken
  defdelegate get_app_token(organization_id), to: Actions.GetAppToken

  @impl Actions.GetCommit
  defdelegate get_commit(by), to: Actions.GetCommit

  @impl Actions.GetInstallation
  defdelegate get_installation(organization_id, installation_id), to: Actions.GetInstallation

  @impl Actions.ImportUsers
  defdelegate import_users(integration), to: Actions.ImportUsers

  @impl Actions.ImportPullRequests
  defdelegate import_pull_requests(integration, repository, opts), to: Actions.ImportPullRequests

  @impl Actions.ImportDefaultBranch
  defdelegate import_default_branch(integration, repository, opts), to: Actions.ImportDefaultBranch

  @impl Actions.ImportRepositories
  defdelegate import_repositories(integration), to: Actions.ImportRepositories

  @impl Actions.ImportCommit
  defdelegate import_commit(attrs, author \\ nil), to: Actions.ImportCommit

  @impl Actions.ImportReview
  defdelegate import_review(attrs), to: Actions.ImportReview

  @impl Actions.UpsertRepository
  defdelegate upsert_repository(attrs), to: Actions.UpsertRepository

  @callback get_user(Keyword.t()) :: {:ok, User.t() | {:error, :github_user_not_found}}
  @impl __MODULE__
  def get_user(by) do
    Storage.get_user(by)
  end

  @callback list_repositories(String.t()) :: [Repository.t()]
  @impl __MODULE__
  def list_repositories(organization_id) do
    Storage.list_repositories(organization_id)
  end

  @callback update_repository(Repository.t(), map()) :: {:ok, Repository.t()}
  @impl __MODULE__
  def update_repository(repository, attrs) do
    Storage.update_repository(repository, attrs)
  end

  @callback get_repository(Keyword.t()) :: {:ok, Repository.t()} | {:error, :repository_not_found}
  @impl __MODULE__
  def get_repository(by) do
    Storage.get_repository(by)
  end

  @decorate cacheable(
              cache: Devhub.Coverbot.Cache,
              key: "pr_files:#{repository.id}:#{number}",
              opts: [ttl: to_timeout(minute: 15)],
              match: fn
                {:ok, _list} -> true
                _error -> false
              end
            )
  def pull_request_files(integration, repository, number) do
    case Client.pull_request_files(integration, repository, number) do
      {:ok, %{status: 200, body: files}} ->
        {:ok, files}

      _error ->
        {:error, :failed_to_fetch_files}
    end
  end

  @callback pull_request_details(Integration.t(), Repository.t(), Integer.t()) :: PullRequest.t()
  @impl __MODULE__
  def pull_request_details(integration, repository, number) do
    query = """
    query PullRequestDetails($name: String!, $owner: String!, $number: Int!) {
      repository(name: $name, owner: $owner) {
        pullRequest(number: $number) {
          reviews (first: 100) {
            nodes {
              id
              author {
                login
              }
              createdAt
            }
          }

          commits(first: 1) {
            nodes {
              commit {
                authoredDate
              }
            }
          }

          timelineItems(itemTypes: [READY_FOR_REVIEW_EVENT], last: 1) {
            nodes {
              ... on ReadyForReviewEvent {
                createdAt
              }
            }
          }
        }
      }
    }

    """

    {:ok,
     %{
       body: %{
         "data" => %{
           "repository" => %{
             "pullRequest" => pull_request
           }
         }
       }
     }} =
      Client.graphql(integration, query, %{
        name: repository.name,
        owner: repository.owner,
        number: number
      })

    pull_request
  end
end
