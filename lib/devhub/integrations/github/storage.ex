defmodule Devhub.Integrations.GitHub.Storage do
  @moduledoc false
  @behaviour __MODULE__

  import Ecto.Query

  alias Devhub.Integrations.GitHub.Repository
  alias Devhub.Integrations.GitHub.User
  alias Devhub.Integrations.Schemas.Integration
  alias Devhub.Repo

  @callback all_integrations() :: [Integration.t()]
  def all_integrations do
    query = from Integration, where: [provider: :github]

    Repo.all(query)
  end

  @callback get_user(Keyword.t()) :: {:ok, User.t() | {:error, :github_user_not_found}}
  def get_user(by) do
    query =
      from gu in User,
        left_join: ou in assoc(gu, :organization_user),
        left_join: lu in assoc(ou, :linear_user),
        where: ^by,
        preload: [organization_user: {ou, linear_user: lu}]

    case Repo.one(query) do
      %User{} = user -> {:ok, user}
      nil -> {:error, :github_user_not_found}
    end
  end

  @callback list_repositories(String.t()) :: [Repository.t()]
  def list_repositories(organization_id) do
    query =
      from r in Repository,
        where: r.organization_id == ^organization_id,
        order_by: [desc: r.pushed_at]

    Repo.all(query)
  end

  @callback get_repository(Keyword.t()) :: {:ok, Repository.t()} | {:error, :repository_not_found}
  def get_repository(by) do
    case Repo.get_by(Repository, by) do
      %Repository{} = repository -> {:ok, repository}
      nil -> {:error, :repository_not_found}
    end
  end

  @callback update_repository(Repository.t(), map()) :: {:ok, Repository.t()}
  def update_repository(repository, attrs) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
  end
end
